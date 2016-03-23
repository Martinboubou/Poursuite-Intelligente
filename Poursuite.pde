public int camWidth = 640;                   //   camera width (pixels),   usually 160*n
public int camHeight = 480;                  //   camera height (pixels),  usually 120*n
boolean PRINT_FRAMERATE = true;              // Affiche les FPS sur l'image

int[] diffPixelsColor = {255, 255, 0};       // Red, green, blue values (0-255)  to show pixel as marked as target
public int effect = 0;                       // Effect

public boolean mirrorCam = false;            //   Inverse l'image ou pas

public float xMin = 0.0;                     //  Actual calibration values are loaded from "settings.txt".
public float xMax = 180.0;                   //  If "settings.txt" is borken / unavailable, these defaults are used instead - 
public float yMin = 0.0;                     //  otherwise, changing these lines will have no effect on your gun's calibration.
public float yMax = 180.0;

import ipcapture.*;
import blobDetection.*;
import processing.serial.*;
import java.awt.Frame;
import processing.opengl.*;                  // see note on OpenGL in void setup() 
import procontroll.*;
import net.java.games.input.*;
import gab.opencv.*;



public int minBlobArea = 30;                 //   minimum target size (pixels)
public int tolerance = 100;                  //   sensitivity to motion

IPCapture camInput;
BlobDetection target;
Blob blob;
Blob biggestBlob;

int[] Background;
int[] rawImage;
int[] rawBackground;
int[] currFrame;
int[] screenPixels;
public int targetX = camWidth/2;
public int targetY = camHeight/2;
int fire = 0;
int[] prevFire = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0};

float xRatio;
float yRatio;

int possibleX = camWidth/2;
int possibleY = camHeight/2;

int displayX = camWidth/2;
int displayY = camHeight/2;

int oldX = camWidth/2;                        // smoothing (contributed by Adam S.)
int oldY = camHeight/2;                       // smoothing
int xdiff;                                    // smoothing
int ydiff;                                    // smoothing
public float smoothingFactor = 0.8;           // smoothing
public boolean activeSmoothing = true;

String strTargetx;
String strTargety;
String fireSelector;
String scanSelector;

public boolean showDifferentPixels = false;
public boolean firingMode = true;
public boolean showTargetBox = true;
public boolean showCameraView = true;
//public boolean controlMode = false;           // true = autonomous,  false = manual
public boolean scanWhenIdle = true;
public boolean trackingMotion = true;

int idleTime = 10000;          // how many milliseconds to wait until scanning (when in scan mode)
int idleBeginTime = 0;
boolean scan = false;

int[][] fireRestrictedZones = new int[30][4];
int restrictedZone = 1;
boolean showRestrictedZones = false;

boolean selectingColor = false;
boolean trackingColor = false;
int trackColorTolerance = 100;
int trackColorRed = 255;
int trackColorGreen = 255;
int trackColorBlue = 255;

boolean selectingSafeColor = false;
boolean safeColor = false;
int safeColorMinSize = 500;
int safeColorTolerance = 100;
int safeColorRed = 0;
int safeColorGreen = 255;
int safeColorBlue = 0;

public float xPosition = camWidth/2;
public float yPosition = camHeight/2;

String[] inStringSplit;  // buffer for backup
int /*controlMode_i,*/ scanWhenIdle_i, trackingMotion_i, trackingColor_i, leadTarget_i, safeColor_i, 
showRestrictedZones_i, showDifferentPixels_i, showTargetBox_i, showCameraView_i, mirrorCam_i;

void setup() {
  
  size(640, 480);
  //minim = new Minim(this);
  camInput = new IPCapture(this, "http://10.132.10.127:8080/video","admin","poursuite");
  camInput.start();
  camInput.read();
  //camInput.adaptivity(1.01);
  camInput.loadPixels();
  currFrame = camInput.pixels;
  rawImage = camInput.pixels;
  Background = camInput.pixels;
  rawBackground = camInput.pixels;
  screenPixels = camInput.pixels;
  target = new BlobDetection(camWidth, camHeight);
  target.setThreshold(0.9);
  target.setPosDiscrimination(true);
  
  xRatio = (camWidth / (xMax - xMin));                         // used to allign sights with crosshairs on PC
  yRatio = (camHeight/ (yMax - yMin));
}

void draw() {
  if (PRINT_FRAMERATE) {
    println(frameRate);
  }
  
  autonomousMode(); 
    strTargetx = "000" + str(targetX);                   // make into 3-digit numbers
  strTargetx = strTargetx.substring(strTargetx.length()-3);
  strTargety = "000" + str(targetY);
  strTargety = strTargety.substring(strTargety.length()-3);
  fireSelector = str(0);
  if (firingMode) {
    fireSelector = str(1);
  }
  else {
    fireSelector = str(3);
  }
  if (scan) {
    scanSelector = str(1);
  }
  else {
    scanSelector = str(0);
  }
  if ((keyPressed && key == 't') || showRestrictedZones) {
    for (int col = 0; col <= restrictedZone; col++) {
      noStroke(); // considère le rectangle mais ne le dessine pas
      fill(0, 255, 0, 100); // La fonction rect dessine un triangle avec comme param 1 & 2 la pos du coin sup gauche et 3 et 4 longueur/largeur
      rect(fireRestrictedZones[col][0], fireRestrictedZones[col][2], fireRestrictedZones[col][1]-fireRestrictedZones[col][0], fireRestrictedZones[col][3]-fireRestrictedZones[col][2]);
    }
  }
  
  if (selectingColor) {
    stroke(190, 0, 190);
    strokeWeight(2);
    fill(red(currFrame[(mouseY*width)+mouseX]), green(currFrame[(mouseY*width)+mouseX]), blue(currFrame[(mouseY*width)+mouseX]));
    rect(mouseX+2, mouseY+2, 30, 30);
  }

  if (selectingSafeColor) {
    stroke(0, 255, 0);
    strokeWeight(2);
    fill(red(currFrame[(mouseY*width)+mouseX]), green(currFrame[(mouseY*width)+mouseX]), blue(currFrame[(mouseY*width)+mouseX]));
    rect(mouseX+2, mouseY+2, 30, 30);
  }
  
  for (int i = 9; i >= 1; i--) {
    prevFire[i] = prevFire[i-1];
  }
  //prevFire[0] = fire;
  //int sumNewFire = prevFire[0] + prevFire[1] + prevFire[2] + prevFire[3] + prevFire[4];
  //int sumPrevFire = prevFire[5] + prevFire[6] + prevFire[7] + prevFire[8] + prevFire[9];
  
   stroke(255, 0, 0);                      //déssine la réticule
  noFill();                                // 
  line(displayX, 0, displayX, camHeight);  //
  line(0, displayY, camWidth, displayY);   //
  ellipse(displayX, displayY, 20, 20);     //
  ellipse(displayX, displayY, 28, 22);     //
  ellipse(displayX, displayY, 36, 24);     //
  
  //updateControlPanels();
  prevTargetX = targetX;
  prevTargetY = targetY;
}

void autonomousMode() {
  
  if (selectingColor || selectingSafeColor) {
    cursor(1);
  }
  else {
    cursor(0);
  }
  camInput.read(); //Update remplacé par updatepixels
  rawBackground = camInput.pixels;
  rawImage = camInput.pixels;
  if (mirrorCam) {
    for (int i = 0; i < camWidth*camHeight; i++) {
      int y = floor(i/camWidth);
      int x = i - (y*camWidth);
      x = camWidth-x;
      currFrame[i] = rawImage[(y*camWidth) + x-1];
      Background[i] = rawBackground[(y*camWidth) + x-1];
    }
  }
  else {
    currFrame = rawImage;
    Background = rawBackground;
  }
  
  loadPixels();
  int safeColorPixelsCounter = 0;

  for (int i = 0; i < camWidth*camHeight; i++) {
    if (showCameraView) {
      pixels[i] = currFrame[i];
    }
    else {
      pixels[i] = color(0, 0, 0);
    }        

    boolean motion = (((abs(red(currFrame[i])-red(Background[i])) + abs(green(currFrame[i])-green(Background[i])) + abs(blue(currFrame[i])-blue(Background[i]))) > (200-tolerance)) && trackingMotion);
    boolean isTrackedColor = (((abs(red(currFrame[i])-trackColorRed) + abs(green(currFrame[i])-trackColorGreen) + abs(blue(currFrame[i])-trackColorBlue)) < trackColorTolerance) && trackingColor);

    boolean isSafeColor = (((abs(red(currFrame[i])-safeColorRed) + abs(green(currFrame[i])-safeColorGreen) + abs(blue(currFrame[i])-safeColorBlue)) < safeColorTolerance) && safeColor);

    if (motion || isTrackedColor) {
      screenPixels[i] = color(255, 255, 255);
      if (showDifferentPixels) {
        if (effect == 0) {
          pixels[i] = color(diffPixelsColor[0], diffPixelsColor[1], diffPixelsColor[2]);
        }
        else if (effect == 1) {
          pixels[i] = color((diffPixelsColor[0] + red(currFrame[i]))/2, (diffPixelsColor[1] + green(currFrame[i]))/2, (diffPixelsColor[2] + blue(currFrame[i]))/2);
        }
        else if (effect == 2) {
          pixels[i] = color(255-red(currFrame[i]), 255-green(currFrame[i]), 255-blue(currFrame[i]));
        }
        else if (effect == 3) {
          pixels[i] = color((diffPixelsColor[0] + (255-red(currFrame[i])))/2, (diffPixelsColor[1] + (255-green(currFrame[i])))/2, (diffPixelsColor[2] + (255-blue(currFrame[i])))/2);
        }
      }
    }
    /*else {
      screenPixels[i] = color(0, 0, 0);
    }*/

    if (isSafeColor) {
      safeColorPixelsCounter++;
      pixels[i] = color(0, 255, 0);
      screenPixels[i] = color(0, 0, 0);
    }
  }



  updatePixels();

  int biggestBlobArea = 0;
 target.computeBlobs(screenPixels);
  for (int i = 0; i < target.getBlobNb()-1; i++) {
    blob = target.getBlob(i);
    int blobWidth = int(blob.w*camWidth);
    int blobHeight = int(blob.h*camHeight);
    if (blobWidth*blobHeight >= biggestBlobArea) {
      biggestBlob = target.getBlob(i);
      biggestBlobArea = int(biggestBlob.w*camWidth)*int(biggestBlob.h*camHeight);
    }
  }
  possibleX = 0;
  possibleY = 0;

  if (biggestBlobArea >= minBlobArea) {
    possibleX = int(biggestBlob.x * camWidth);
    possibleY = int(biggestBlob.y * camHeight);
  }


  if ((biggestBlobArea >= minBlobArea)) {
    fire = 1;
    if (showTargetBox) {
      stroke(255, 50, 50);
      strokeWeight(3);
      fill(255, 50, 50, 150);
      rect(int(biggestBlob.xMin*camWidth), int(biggestBlob.yMin*camHeight), int((biggestBlob.xMax-biggestBlob.xMin)*camWidth), int((biggestBlob.yMax-biggestBlob.yMin)*camHeight));
    }

    anticipation();

    if (activeSmoothing) {
      xdiff = possibleX - oldX; // smoothing
      ydiff = possibleY - oldY; // smoothing
      possibleX = int(oldX + xdiff*(1.0-smoothingFactor)); // smoothing
      possibleY = int(oldY + ydiff*(1.0-smoothingFactor)); // smoothing
    }

    displayX = possibleX;
    displayY = possibleY;
    if (displayX < 0)
      displayX = 0;
    if (displayX > camWidth)
      displayX = camWidth;
    if (displayY < 0)
      displayY = 0;
    if (displayY > camHeight)
      displayY = 0;  
    targetX = int((possibleX/xRatio)+xMin);         
    targetY = int(((camHeight-possibleY)/yRatio)+yMin);
    oldX = possibleX; // smoothing
    oldY = possibleY; // smoothing
  }
  else {
    fire = 0;
  }

  boolean clearOfZones = true;
  for (int col = 0; col <= restrictedZone; col++) {
    if (possibleX > fireRestrictedZones[col][0] && possibleX < fireRestrictedZones[col][1] && possibleY > fireRestrictedZones[col][2] && possibleY < fireRestrictedZones[col][3]) {
      clearOfZones = false;
      fire = 0;
    }
  }


  if (safeColorPixelsCounter > safeColorMinSize && safeColor) {
    noStroke();
    fill(0, 255, 0, 150);
    rect(0, 0, width, height);
    fire = 0;
    targetX = int((xMin+xMax)/2.0);
    targetY = int(yMin);
    displayX = camWidth/2;
    displayY = camHeight;
  }
}

public void stop() {
  camInput.stop();
  super.stop();
}