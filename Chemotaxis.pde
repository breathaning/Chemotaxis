// game classes
class Bacterium {
  float x, y, z;
  CFrame cframe;
  color colour;
  Bacterium(float x, float y, float z, color colour) {
    this.x = x;
    this.y = y;
    this.z = z;
    this.colour = colour;
    this.cframe = new CFrame().translateLocal(new PVector(x, y, z));
  }
  
  void update() {
    float step = 5;
    cframe.rotateEuler(new PVector(randomFloat(0, TWO_PI), randomFloat(0, TWO_PI), randomFloat(0, TWO_PI)));
    cframe.translateLocal(new PVector(0, 0, randomFloat(0, step)));
  }
  
  void show() {
    fill(colour);
    noStroke();
    PVector v = cframe.position();
    translate(v.x, v.y, v.z);
    sphere(5);
  }
}

class CFrame {
  PMatrix3D matrix;
  
  CFrame() {
    matrix = new PMatrix3D();
  }
  
  PVector position() {
    float[] a = new float[16];
    a = matrix.get(a);
    return new PVector(a[3], a[7], a[11]);
  }
  
  CFrame translateGlobal(PVector translation) {
    matrix.translate(translation.x, translation.y, translation.z);
    return this;
  }
  
  CFrame translateLocal(PVector v) {
    float[] a = new float[16];
    a = matrix.get(a);
    PVector fv = matrix.mult(v, new PVector(0, 0, 0));
    matrix.set(
      a[0], a[1], a[2], fv.x,
      a[4], a[5], a[6], fv.y,
      a[8], a[9], a[10], fv.z,
      0, 0, 0, 1
    );
    return this;
  }
  
  CFrame rotateEuler(PVector rotation) {
    matrix.rotateX(rotation.x);
    matrix.rotateY(rotation.y);
    matrix.rotateZ(rotation.z);
    return this;
  }
}

// game functions
void updateTime() {
  
}


// util functions 
color randomColor() {
  return color(randomFloat(0, 255), randomFloat(0, 255), randomFloat(0, 255));
}

float randomFloat(float min, float max) {
  return min + (float)(Math.random() * (max - min));
}

boolean isKeyPressed(char key) {
  return keysPressed.indexOf(key) >= 0;
}

// game variables
ArrayList<Character> keysPressed = new ArrayList();

Bacterium[] bacteria = new Bacterium[50];

CFrame cameraCFrame = new CFrame();
{
  cameraCFrame.translateGlobal(new PVector(0, 0, -10));
}

void setup() {
  size(750, 750, P3D);
  for (int i = 0; i < bacteria.length; i++) {
    CFrame cframe = new CFrame();
    cframe.rotateEuler(new PVector(randomFloat(0, TWO_PI), randomFloat(0, TWO_PI), randomFloat(0, TWO_PI)));
    bacteria[i] = new Bacterium((float)Math.random() * width, (float)Math.random() * height, (float)Math.random() * height, randomColor());
  }
}

void draw() {
  background(100);
  lights();
  for (int i = 0; i < bacteria.length; i++) {
    bacteria[i].update();
    pushMatrix();
    bacteria[i].show();
    popMatrix();
  }
}

void keyPressed() {
  if (isKeyPressed(key)) return;
  keysPressed.add(key);
}

void keyReleased() {
  if (!isKeyPressed(key)) return;
  keysPressed.remove(key);
}
