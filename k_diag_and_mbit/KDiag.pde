// Array is [count, destination, length1, length2]
class Arc {
   int count, destination, len1, len2; 
  
  Arc(int c, int d, int l1, int l2) {
    count=c;
    destination=d;
    len1=l1;
    len2=l2;
  }
}

class EndOfSequenceException extends Exception {}

class Node {  
  ArrayList<Arc> nexts;
  double a, rad;
  int x,y,currentWait;

   
  Node(double a, double rad) {
    nexts = new ArrayList<Arc>();
    currentWait=0;
    newPosition(a,rad);
  }
 
  void newPosition(double a, double rad) {
    this.a=a;
    this.rad=rad;
    x=(int)(Math.cos(a)*rad);
    y=(int)(Math.sin(a)*rad);
  }
  
  void addArc(int to, int l1, int l2) {
    nexts.add(new Arc(0,to,l1,l2));
  }

  int countTotalVisits() {
    int total = 0;
    for (Arc a : nexts) { total = total + a.count; }
    return total;
  }  
  
  int chooseNext() throws EndOfSequenceException {
    if (nexts.size() == 0) { throw new EndOfSequenceException(); }
    int[] inverts = new int[nexts.size()];
    int total = countTotalVisits();
    int i=0;
    int tot2=0;
    for (Arc a : nexts) { 
      inverts[i]=total - a.count;
      tot2=tot2+a.count;
      i++; 
    }
    int find = (int)(Math.random()*tot2);
    int tracker = 0;
    for (i=0;i<nexts.size();i++) {
      if (find < tracker + inverts[i]) {
        Arc a = nexts.get(i);
        currentWait = a.len1; 
        return a.destination; 
      }
      tracker=tracker+inverts[i];
    }
    Arc a = nexts.get(i-1);
    currentWait = a.len1; 
    return a.destination; 
  }

  void updateCounter(int dest) {
    for (Arc a : nexts) {
      if (a.destination == dest) { a.count++;  return; }
    }
  }

  void rotate(float da) {
    newPosition(a+da,rad);
  }

  // UI

  boolean hit(int ox, int oy) {
    int dx = Math.abs(x-ox);
    int dy = Math.abs(y-oy);
    if ( (dx<20) && (dy<20)) { return true; }
    return false;    
  }
  
  void draw() {
    pushStyle();
    fill(50,100,210);      
    ellipse(x,y,20,20);
    popStyle();    
  }
  
  void drawHighlighted() {
    pushStyle();
    fill(200,0,30);      
    ellipse(x,y,20,20);
    popStyle();    
  }  

} 


class Network {
  ArrayList<Node> nodes = new ArrayList<Node>();
  int rad;
  int currentWait;
  
  Network(int aRad, int noNodes, int arcsPerNode) {
    rad = aRad;
    // random initializer
    for (int i=0;i<noNodes;i++) {
      double a = Math.random() * PI * 2;
      int r = (int)(0.2 + (0.8 * Math.random() * rad));     
      Node n = new Node(Math.random()*2*PI,rad/3 + (Math.random()*2*rad/3));      
      for (int j=0;j<(int)(Math.random()*arcsPerNode);j++) {
        int k = i;
        while (k==i) {
          k = (int)(Math.random()*noNodes);
        }
        n.addArc(k,(int)(Math.random()*10),(int)(Math.random()*10));       
      }
      nodes.add(n);
    }
  }
  
  void draw() {
    pushMatrix();
    translate(320,240);
    for (Node n : nodes) {
      n.draw();
      for (Arc a : n.nexts) {
        stroke(255,200,100);
        Node dest = nodes.get(a.destination);
        line(n.x,n.y,dest.x,dest.y);
        int hx = (n.x + (int)((dest.x-n.x)*0.9));
        int hy = (n.y + (int)((dest.y-n.y)*0.9));
        ellipse(hx,hy,5,5);
        
        noStroke();
      }
    }
    noFill();
    stroke(200,200,100);
    ellipse(0,0,rad*2,rad*2);
    popMatrix();
  }
  

  int nextFrom(int from) throws EndOfSequenceException {
    Node node = nodes.get(from);    
    int dest = node.chooseNext();    
    node.updateCounter(dest);
    currentWait = node.currentWait;
    return dest;
  }
  
  int selected(int x, int y, int xOffset, int yOffset) {
    for (int i=0;i<nodes.size();i++) {
      if ((nodes.get(i)).hit(x-xOffset,y-yOffset)) { return i; }
    }
    return -1;   
  }

  Node getNode(int i) { return nodes.get(i); }
 
  void rotate(float da) {
    for (Node n : nodes) { n.rotate(da); }
  } 
}

interface HasNetwork {
  void recreateNetwork(int aRad, int noNodes, int arcsPerNode);
  Network getNetwork();
  int selected(int x, int y, int xOffset, int yOffset);
}

class KDiag implements IControlAutomaton {
    
  class UncertainY implements IFreqStrategy {
    float noise;
    float high;
    
    UncertainY(float h, float n) {
      high = h; 
      noise = n;  
    }
    
   float rawFreq(float y) {
      return map(y, -high/2, high/2, 1000,0 ); 
   }
    
   float corrected(float f) {
      return (float)(f - (noise/2) + (Math.random()*noise));
    }
  }

  
  Network network;
  IFreqStrategy fs = new IdentityFreqStrategy();
  ArrayList<ObservingInstrument> obis = new ArrayList<ObservingInstrument>();

  boolean playing = false;

  boolean currentlyOn = true; 
  
  int currentNode; 
  int wait = 50;
  
  KDiag(int aRad, int noNodes, int arcsPerNode) { 
    recreateNetwork(aRad,noNodes,arcsPerNode); 
  }
  
  Network getNetwork() { return network; }
  
  int selected(int x, int y, int xOffset, int yOffset) { 
    int find = network.selected(x,y,xOffset,yOffset);
    if (find > -1) { currentNode = find; } 
    return find;
  }

  void recreateNetwork(int aRad, int noNodes, int arcsPerNode) { 
    network = new Network(aRad,noNodes,arcsPerNode);
    currentNode = 0;     
  }
 

  void addObservingInstrument(ObservingInstrument oi) {
    obis.add(oi); 
  }

  boolean isPlaying() { return playing; }
  void start() {
    playing = true; 
  }
  void stop() { 
    playing = false; 
  }  

  void playNote(float freq) {
    if (isPlaying()) {
      for (ObservingInstrument oi : obis) {
        oi.playNote(freq);
      }
    }
  }
  
  void nextStep() {
    if (!isPlaying()) { return; }
  
    if (frameCount % (1+wait) == 0) { 
      try {
        currentNode = network.nextFrom(currentNode);
        wait = network.currentWait*5;
        Node node = network.getNode(currentNode);
        playNote(fs.corrected(fs.rawFreq(node.y)));      
      } catch (EndOfSequenceException e) {
        //println("End of sequence from " + currentNode);
        currentNode = 0;
        kDiag.stop();      
        wait = 20;
      }   
    }    
  }
  
  void draw() {
    network.draw();
    Node cNode = network.nodes.get(currentNode);
    pushMatrix();
      translate(320,240);
      cNode.drawHighlighted();
    popMatrix(); 
  }

  void struck(int x, int y) {
    if (!currentlyOn) { return; }
    
    int find = selected(x,y,320,240);
    
    if (find > -1) { 
      start();
      Node node = network.nodes.get(currentNode);
      playNote(fs.corrected(fs.rawFreq(node.y)));  
    }  
  }

  void keyPressed(int k) {
    switch (k) {
      case 32 : reset();
        return;
      case 91 : getNetwork().rotate(-0.01);
        return;
      case 93 : getNetwork().rotate(0.01);
        return;
      case 'a' : 
        currentlyOn = true;
        println("currentlyOn = true");
        return;
      case 'z' : 
        currentlyOn = false;
        println("currentlyOn = false");
        return;
    } 
  }

  void sizeInSetup() {
      
  }

  void reset() {
    recreateNetwork(240, 15 ,6);
    setIFreqStrategy(new UncertainY(height,100));    
  }

  void setIFreqStrategy(IFreqStrategy fs) { this.fs = fs; }
  IFreqStrategy getIFreqStrategy() { return fs; }

}
 