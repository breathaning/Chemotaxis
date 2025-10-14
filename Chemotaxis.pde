// constants
final int SIMULATION_RATE = 60;
final float SIMULATION_INTERVAL = 1f / SIMULATION_RATE;
final float CAMERA_MOUSE_SENSITIVITY = 0.008;
final float CAMERA_SPEED = 15;
final PVector CAMERA_START_SETPOINT = new PVector(0, 0, -100);
final float BACTERIA_IDLE_SHAKE = 16;
final float BACTERIA_TERMINAL_SPEED = 48;
final float BACTERIA_KINETIC_FRICTION = 0.3;
final float BIAS_DISTANCE = 1000;
final float BIAS_MINIMUM_ACCELERATION = 1;
final PVector PVECTOR_ZERO = new PVector(0, 0, 0);
final PVector PVECTOR_X = new PVector(1, 0, 0);
final PVector PVECTOR_Y = new PVector(0, 1, 0);
final PVector PVECTOR_Z = new PVector(0, 0, 1);

// game classes 
class Bacterium {
  int x, y, z;
  CFrame cframe;
  color colour;
  PVector velocity;
  PVector acceleration;

  Bacterium(int x, int y, int z, color colour) {
    this.x = x;
    this.y = y;
    this.z = z;
    this.colour = colour;
    this.cframe = new CFrame().translateGlobal(new PVector(x, y, z));
    this.velocity = PVECTOR_ZERO.get();
    this.acceleration = PVECTOR_ZERO.get();
  }
  
  void move(float deltaTick) {
    PVector velocityDirection = velocity.get();
    velocityDirection.normalize();
    PVector frictionAcceleration = velocityDirection.get();
    frictionAcceleration.mult(BACTERIA_KINETIC_FRICTION);

    PVector netAcceleration = acceleration.get();
    netAcceleration.sub(frictionAcceleration);

    PVector scaledAcceleration = netAcceleration;
    scaledAcceleration.mult(deltaTick);

    if (acceleration.mag() == 0  && velocity.mag() < frictionAcceleration.mag()) {
      velocity.mult(0);
    } else {
      velocity.add(scaledAcceleration);
    }

    maxVectorMagnitude(velocity, BACTERIA_TERMINAL_SPEED);

    PVector scaledVelocity = velocity.get();
    scaledVelocity.mult(deltaTick);
    cframe.translateGlobal(scaledVelocity);

    // random shake
    cframe.rotateEuler(new PVector(randomFloat(0, TWO_PI), randomFloat(0, TWO_PI), randomFloat(0, TWO_PI)));
    cframe.translateLocal(new PVector(0, 0, randomFloat(0, BACTERIA_IDLE_SHAKE * deltaTick)));

    // yes
    PVector position = cframe.position();
    x = (int)position.x;
    y = (int)position.y;
    z = (int)position.z;
  }
  
  void show() {
    fill(colour);
    noStroke();
    translate(x, y, z);
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
    result.setPosition(PVECTOR_ZERO);
    return result;
  }

  PVector lookVector() {
    return vectorToGlobalSpace(PVECTOR_Z);
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
    PVector translatedPosition = position();
    translatedPosition.add(translation);
    setPosition(translatedPosition);
    return this;
  }
  
  CFrame translateLocal(PVector translation) {
    matrix.translate(translation.x, translation.y, translation.z);
    return this;
  }
  
  CFrame rotateEuler(PVector rotation) {
    matrix.rotateX(rotation.x);
    matrix.rotateY(rotation.y);
    matrix.rotateZ(rotation.z);
    return this;
  }

  PVector vectorToGlobalSpace(PVector vector) {
    return rotation().matrix.mult(vector.get(), new PVector(0, 0, 0));
  }
}

// game functions
void updateTime() {
  float oldActualSeconds = actualSeconds;
  actualSeconds = (float)millis() / 1000;
  deltaSeconds = Math.min(SIMULATION_INTERVAL, actualSeconds - oldActualSeconds);
  deltaTick = deltaSeconds / SIMULATION_INTERVAL;
  seconds += deltaSeconds;
}

void updateInput() {
  // mouse
  mouseChanged = (pmousePressed != mousePressed);
  if (mouseChanged) {
    pmousePressed = mousePressed;
  }
}

void updatePhysics(float deltaTick) {
  if (mousePressed) {
    PVector biasCenter = getBiasCenter();
    for (int i = 0; i < bacteria.length; i++) {
      PVector acceleration = biasCenter.get();
      acceleration.sub(bacteria[i].cframe.position());
      acceleration.mult(0.001);
      minVectorMagnitude(acceleration, BIAS_MINIMUM_ACCELERATION);
      bacteria[i].acceleration = acceleration;
    }
  } else {
    for (int i = 0; i < bacteria.length; i++) {
      bacteria[i].acceleration = PVECTOR_ZERO.get();
    }
  }

  for (int i = 0; i < bacteria.length; i++) {
    bacteria[i].move(deltaTick);
  }
}

void updateBurstState() {
  float sumDistance = 0;
  PVector biasCenter = getBiasCenter();
  for (int i = 0; i < bacteria.length; i++) {
    sumDistance += bacteria[i].cframe.position().dist(biasCenter);
  }
  float averageDistance = sumDistance / bacteria.length;
  pcanBurst = canBurst;
  canBurst = (averageDistance < 64);
  canBurstChanged = (canBurst != pcanBurst);
  if (canBurstChanged) {
    burstStateChangeSeconds = seconds;
  }
  if (canBurst && mouseChanged && !mousePressed) {
    for (int i = 0; i < bacteria.length; i++) {
      bacteria[i].velocity.mult(randomFloat(-10, -6));
      minVectorMagnitude(bacteria[i].velocity, 8);
      maxVectorMagnitude(bacteria[i].velocity, 32);
    }
  }
}

void updateCamera() {
  int left = 0;
  if (isKeyPressed('a')) left++;
  if (isKeyPressed('d')) left--;

  int forward = 0;
  if (isKeyPressed('w')) forward++;
  if (isKeyPressed('s')) forward--;

  int up = 0;

  PVector localDirection = new PVector(left, 0, forward);
  localDirection.mult(CAMERA_SPEED * deltaTick);
  cameraCFrame.translateLocal(localDirection);
  PVector globalDirection = new PVector(0, up, 0);
  globalDirection.mult(CAMERA_SPEED * deltaTick);
  cameraCFrame.translateGlobal(globalDirection);

  PVector cameraPosition = cameraCFrame.position();
  CFrame cameraCenterCFrame = cameraCFrame.copy();
  cameraCenterCFrame.translateLocal(new PVector(0, 0, 1));
  PVector cameraCenter = cameraCenterCFrame.position();
  PVector upVector = cameraCFrame.vectorToGlobalSpace(PVECTOR_Y);
  camera(
    cameraPosition.x, cameraPosition.y, cameraPosition.z, 
    cameraCenter.x, cameraCenter.y, cameraCenter.z,
    upVector.x, upVector.y, upVector.z
  );

  float fov = PI / 3.0;
  float cameraZ = (height / 2f) / (float)Math.tan(fov / 2);
  float elapsedTime = seconds - lastMouseChange - deltaSeconds;
  if (mouseChanged) {
    pscreenAspectRatio = screenAspectRatio;
    if (mousePressed == false) {
      playCameraBounce = pcanBurst;
    }
  }
  if (mousePressed) {
    float targetScreenAspectRatio = getDefaultScreenAspectRatio() * (float)Math.pow(2, Math.sin(elapsedTime * 2));
    screenAspectRatio += (targetScreenAspectRatio - screenAspectRatio) / 5;
  } else {
    if (playCameraBounce) {
      float tweenAlphaLinear = tweenLinear(elapsedTime * 4);
      float tweenAlphaElastic = tweenElastic(elapsedTime * 0.9);
      float startScreenAspectRatio = pscreenAspectRatio + (tweenAlphaLinear * (0.01 - pscreenAspectRatio));
      screenAspectRatio = startScreenAspectRatio + (tweenAlphaElastic * (getDefaultScreenAspectRatio() - startScreenAspectRatio));
    } else {
      screenAspectRatio += (getDefaultScreenAspectRatio() - screenAspectRatio) / 5;
    }
  }
  perspective(fov, screenAspectRatio, cameraZ / 64f, cameraZ * 32f);
}

void drawBackground() {
  color targetBackgroundColor;
  float tweenAlphaLinear;

  if (burstStateChangeSeconds == 0) {
    targetBackgroundColor = backgroundColor;
    tweenAlphaLinear = 0;
  } else if (canBurst) {
    tweenAlphaLinear = tweenLinear((seconds - burstStateChangeSeconds) * 0.75);
    targetBackgroundColor = lerpColor(pbackgroundColor, color(200), tweenAlphaLinear);
  } else {
    tweenAlphaLinear = tweenLinear((seconds - burstStateChangeSeconds) * 4);
    targetBackgroundColor = lerpColor(pbackgroundColor, color(100), tweenAlphaLinear);
  }

  if (canBurstChanged || burstStateChangeSeconds == 0) {
    pbackgroundColor = backgroundColor;
  }

  backgroundColor = lerpColor(pbackgroundColor, targetBackgroundColor, tweenAlphaLinear);
  background(backgroundColor);
}

void updateLights() {
  PVector cameraPosition = cameraCFrame.position();
  pushMatrix();
  translate(cameraPosition.x, cameraPosition.y, cameraPosition.z);
  noLights();
  lights();
  directionalLight(128, 128, 128, 0, 1, 0);
  lightSpecular(128, 128, 128);
  shininess(50);
  specular(255, 255, 255);
  popMatrix();
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

float tweenLinear(float t) {
  if (t <= 0) return 0;
  if (t >= 1) return 1;
  return t;
}

float tweenElastic(float t) {
  if (t <= 0) return 0;
  if (t >= 1) return 1;
  float scale = 10;
  return (float)Math.pow(2, -t * scale) * (float)Math.sin((t * scale * 21 * PI / 20) - HALF_PI) + 1;
}

PVector getBiasCenter() {
  PVector biasOffset = cameraCFrame.lookVector();
  biasOffset.mult(BIAS_DISTANCE);
  PVector biasCenter = cameraCFrame.position();
  biasCenter.add(biasOffset);
  return biasCenter;
}

void minVectorMagnitude(PVector vector, float min) {
  if (vector.mag() > min) return;
  vector.normalize();
  vector.mult(min);
}

void maxVectorMagnitude(PVector vector, float max) {
  if (vector.mag() < max) return;
  vector.normalize();
  vector.mult(max);
}

// game variables
float actualSeconds = 0;
float seconds = 0;
float deltaSeconds = 0;
float deltaTick = 0;

// screen
float screenAspectRatio = 1;
float pscreenAspectRatio = screenAspectRatio;

// input
ArrayList<Character> keysPressed = new ArrayList();
boolean mouseChanged = false;
boolean pmousePressed = false;
float lastMouseChange = 0;

// sim
float lastSimulation = 0;

// camera
boolean playCameraBounce = false;
CFrame cameraCFrame = new CFrame();

// main
Bacterium[] bacteria = new Bacterium[500];
boolean canBurst = false;
boolean pcanBurst = canBurst;
boolean canBurstChanged = false;

// draw
float burstStateChangeSeconds = 0;
color backgroundColor = color(100);
color pbackgroundColor = pbackgroundColor;

// loops
void setup() {
  frameRate(240);
  size(1200, 800, P3D);

  screenAspectRatio = getDefaultScreenAspectRatio();
  pscreenAspectRatio = screenAspectRatio;

  cameraCFrame.setPosition(CAMERA_START_SETPOINT);
  for (int i = 0; i < bacteria.length; i++) {
    CFrame cframe = new CFrame();
    cframe.rotateEuler(new PVector(randomFloat(0, TWO_PI), randomFloat(0, TWO_PI), randomFloat(0, TWO_PI)));
    float radius = (float)Math.sqrt(Math.random()) * (width + height) / 2;
    PVector position = cframe.vectorToGlobalSpace(new PVector(0, 0, radius));
    bacteria[i] = new Bacterium((int)position.x, (int)position.y, (int)position.z, randomColor());
  }
}

void draw() {
  updateTime();
  updateInput();
  
  updatePhysics(deltaTick);
  
  updateBurstState();
  updateCamera();
  drawBackground();
  updateLights();
  for (int i = 0; i < bacteria.length; i++) {
    pushMatrix();
    bacteria[i].show();
    popMatrix();
  }
}

// input events
void keyPressed() {
  if (isKeyPressed((Character)key)) return;
  keysPressed.add((Character)key);
}

void keyReleased() {
  if (!isKeyPressed((Character)key)) return;
  keysPressed.remove((Character)key);
}

void mousePressed() {
  lastMouseChange = seconds;
  noCursor();
}

void mouseReleased() {
  lastMouseChange = seconds;
  cursor();
}

void mouseDragged() {
  PVector rotation = new PVector(mouseY - pmouseY, mouseX - pmouseX, 0);
  rotation.mult(-CAMERA_MOUSE_SENSITIVITY);
  cameraCFrame.rotateEuler(rotation);
}
