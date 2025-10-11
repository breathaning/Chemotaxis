// constants
final int SIMULATION_RATE = 60;
final float SIMULATION_INTERVAL = 1f / SIMULATION_RATE;

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
    this.cframe = new CFrame().translateGlobal(new PVector(x, y, z));
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
    sphere(10);
  }
}

class CFrame {
  PMatrix3D matrix;
  
  CFrame() {
    matrix = new PMatrix3D();
  }

  CFrame copy() {
    CFrame clone = new CFrame();
    clone.matrix.set(matrix.get());
    return clone;
  }
  
  PVector position() {
    float[] m = new float[16];
    m = matrix.get(m);
    return new PVector(m[3], m[7], m[11]);
  }

  CFrame rotation() {
    CFrame result = this.copy();
    result.setPosition(new PVector(0, 0, 0));
    return result;
  }

  PVector lookVector() {
    return vectorToGlobalSpace(new PVector(0, 0, 1));
  }
  
  CFrame setPosition(PVector vector) {
    float[] m = new float[16];
    m = matrix.get(m);
    matrix.set(
      m[0], m[1], m[2], vector.x,
      m[4], m[5], m[6], vector.y,
      m[8], m[9], m[10], vector.z,
      0, 0, 0, 1
    );
    return this;
  }
  
  CFrame translateGlobal(PVector translation) {
    matrix.translate(translation.x, translation.y, translation.z);
    return this;
  }
  
  CFrame translateLocal(PVector vector) {
    float[] m = new float[16];
    m = matrix.get(m);
    PVector translatedVector = matrix.mult(vector, new PVector(0, 0, 0));
    setPosition(translatedVector);
    return this;
  }
  
  CFrame rotateEuler(PVector rotation) {
    matrix.rotateX(rotation.x);
    matrix.rotateY(rotation.y);
    matrix.rotateZ(rotation.z);
    return this;
  }

  PVector vectorToGlobalSpace(PVector vector) {
    return rotation().matrix.mult(vector, new PVector(0, 0, 0));
  }
}

// game functions
void updateInput() {
  mouseChanged = (pmousePressed != mousePressed);
  if (mouseChanged) {
    pmousePressed = mousePressed;
  }
}

void updateTime() {
  float oldSeconds = seconds;
  seconds = (float)millis() / 1000;
  deltaSeconds = seconds - oldSeconds;
  deltaTick = deltaSeconds / SIMULATION_INTERVAL;
}

void updateCamera() {
  int left = 0;
  if (isKeyPressed('a')) left++;
  if (isKeyPressed('d')) left--;

  int forward = 0;
  if (isKeyPressed('w')) forward++;
  if (isKeyPressed('s')) forward--;

  int up = 0;

  int speed = 25;
  PVector localDirection = new PVector(left, 0, forward);
  localDirection.mult(speed * deltaTick);
  cameraCFrame.translateLocal(localDirection);
  PVector globalDirection = new PVector(0, up, 0);
  globalDirection.mult(speed * deltaTick);
  cameraCFrame.translateGlobal(globalDirection);

  PVector cameraPosition = cameraCFrame.position();
  CFrame cameraCenterCFrame = cameraCFrame.copy();
  cameraCenterCFrame.translateLocal(new PVector(0, 0, 1));
  PVector cameraCenter = cameraCenterCFrame.position();
  PVector upVector = cameraCFrame.vectorToGlobalSpace(new PVector(0, 1, 0));
  camera(
    cameraPosition.x, cameraPosition.y, cameraPosition.z, 
    cameraCenter.x, cameraCenter.y, cameraCenter.z,
    upVector.x, upVector.y, upVector.z
  );

  float fov = PI/3.0;
  float cameraZ = (height / 2f) / Math.tan(fov / 2f);
  if (mouseChanged) {
    previousScreenAspectRatio = screenAspectRatio;
  }
  if (mousePressed) {
    float elapsedTime = seconds - lastMousePress - deltaSeconds;
    float timeScale = 2;
    float targetScreenAspectRatio = getDefaultScreenAspectRatio() * (float)Math.pow(2, Math.sin(elapsedTime * timeScale));
    float tweenAlpha = Math.min(1, elapsedTime / 1f);
    screenAspectRatio += (targetScreenAspectRatio - screenAspectRatio) / 5;
  } else {
    float elapsedTime = seconds - lastMouseRelease - deltaSeconds;
    float timeScale = 4;
    float tweenAlpha = Math.pow(2, -timeScale * elapsedTime) * Math.sin((elapsedTime * timeScale * TWO_PI) - HALF_PI) + 1;
    screenAspectRatio = previousScreenAspectRatio + (tweenAlpha * (getDefaultScreenAspectRatio() - previousScreenAspectRatio));
  }
  perspective(fov, screenAspectRatio, cameraZ/64f, cameraZ*32f);
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

float getDefaultScreenAspectRatio() {
  return (float)width / (float)height;
}

// game variables
float seconds = 0;
float deltaSeconds = 0;
float deltaTick = 0;

float screenAspectRatio = 1;
float previousScreenAspectRatio = screenAspectRatio;

ArrayList<Character> keysPressed = new ArrayList();
boolean mouseChanged = false;
boolean pmousePressed = false;
float lastMousePress = 0;
float lastMouseRelease = 0;

Bacterium[] bacteria = new Bacterium[500];

CFrame cameraCFrame = new CFrame();
{
  cameraCFrame.translateGlobal(new PVector(0, 0, -100));
}

void setup() {
  frameRate(240);
  size(750, 750, P3D);

  screenAspectRatio = getDefaultScreenAspectRatio();

  for (int i = 0; i < bacteria.length; i++) {
    CFrame cframe = new CFrame();
    cframe.rotateEuler(new PVector(randomFloat(0, TWO_PI), randomFloat(0, TWO_PI), randomFloat(0, TWO_PI)));
    float radius = (float)Math.sqrt(Math.random()) * (width + height) / 2;
    PVector position = cframe.vectorToGlobalSpace(new PVector(0, 0, radius));
    bacteria[i] = new Bacterium(position.x, position.y, position.z, randomColor());
  }
}

void draw() {
  updateInput();
  updateTime();
  updateCamera();
  background(100);
  {
    PVector cameraPosition = cameraCFrame.position();
    PVector cameraLookVector = cameraCFrame.lookVector();
    pushMatrix();
    translate(cameraPosition.x, cameraPosition.y, cameraPosition.z);
    noLights();
    lights();
    directionalLight(128, 128, 128, cameraLookVector.x, cameraLookVector.y, cameraLookVector.z);
    lightSpecular(128, 128, 128);
    shininess(50);
    specular(255, 255, 255);
    popMatrix();
  }
  for (int i = 0; i < bacteria.length; i++) {
    bacteria[i].update();
    pushMatrix();
    bacteria[i].show();
    popMatrix();
  }
}

void keyPressed() {
  if (isKeyPressed((Character)key)) return;
  keysPressed.add((Character)key);
}

void keyReleased() {
  if (!isKeyPressed((Character)key)) return;
  keysPressed.remove((Character)key);
}

void mousePressed() {
  lastMousePress = seconds;
  noCursor();
}

void mouseReleased() {
  lastMouseRelease = seconds;
  cursor();
}

void mouseDragged() {
  PVector rotation = new PVector(mouseY - pmouseY, mouseX - pmouseX, 0);
  rotation.mult(-0.01);
  cameraCFrame.rotateEuler(rotation);
}
