import ipcapture.*;
import gab.opencv.*;
import processing.video.*;
import java.awt.Rectangle;

IPCapture video;
OpenCV opencv;
java.awt.Rectangle Rectangle;
ArrayList<Contour> contours;
Capture cam;
PImage img;
PImage adaptive;

void setup() {
  size(640, 480);
  
  //si utilisation camera IP
  /*
  video = new IPCapture(this,"http://10.132.8.102:8080/video","admin","poursuite");
  video.start();
  */
  
  //si utilisation webcam
    
  cam = new Capture(this, 640,480);
        // Comment the following line if you use Processing 1.5
      cam.start();
        

  
  opencv = new OpenCV(this, 640, 480);
  opencv.startBackgroundSubtraction(5,3,0.2);
  
  //filtre adaptive
  //opencv.adaptiveThreshold(591, 1);
  
  //utilisation img comme copie image pour blobscanner
 img = new PImage(80,60); 
  
}

void draw() {
  
  
  //si utilisation camera IP
  
  
  //image(video, 0, 0); 
  
  ////copie image 
  //img.copy(video, 0, 0, video.width, video.height, 
  //     0, 0, img.width, img.height);
        
  ////filtre image pour meilleur detection avec algo fastblur
  //fastblur(img, 1);
  
  //video.read();
  
  
  
  //// sans filtre blur
  //opencv.loadImage(video);
  
  ////avec filtre blur
  //opencv.loadImage(img);
  
  
  
  //si utilisation webcam
  
  image(cam, 0, 0);
  
  img.copy( cam, 0, 0, 640, 480, 0, 0, 640, 480);
        
  //fastblur(img, 0);
  cam.read();
  opencv.loadImage(cam);
  
  opencv.updateBackground();
  
  opencv.dilate();
  opencv.erode();
  
  // filtre daptive sur image
  
  /*
  PImage gray = opencv.getSnapshot();
  opencv.loadImage(gray);
  adaptive = opencv.getSnapshot();
  image(adaptive, img.width, img.height);
  */


// Code Martin 

  
  //noFill();
  //stroke(255, 0, 0);
  //strokeWeight(3);
  
  
  //for (Contour contour : opencv.findContours()) {
  // contour.draw();
  // Rectangle = contour.getBoundingBox();
   //println(Rectangle);
   //rect(Rectangle.x, Rectangle.y, Rectangle.width, Rectangle.height);
    
    
    
    
       // <7> Find contours in our range image.
  //     Passing 'true' sorts them by descending area.
    contours = opencv.findContours(true, true);
   // contours.draw();
    
    // <9> Check to make sure we've found any contours
  if(contours.size() > 0) {
    // <9> Get the first contour, which will be the largest one
    Contour biggestContour = contours.get(0);
    
    biggestContour = biggestContour.getConvexHull();
    biggestContour.draw();
    
  //  <10> Find the bounding box of the largest contour, and hence our object.
    Rectangle r = biggestContour.getBoundingBox();
   
    // <11> Draw the bounding box of our object
    noFill(); 
    strokeWeight(2); 
    stroke(255, 150, 0);
    rect(r.x, r.y, r.width, r.height);
    ellipse(r.x + r.width/2, r.y + r.height/2, r.width/4, r.height/4);
  }
    
}

void movieEvent(Movie m) {
  m.read();
}

// ==================================================
// Super Fast Blur v1.1
// by Mario Klingemann 
// <http://incubator.quasimondo.com>
// ==================================================

void fastblur(PImage img,int radius)
{
 if (radius<1){
    return;
  }
  int w=img.width;
  int h=img.height;
  int wm=w-1;
  int hm=h-1;
  int wh=w*h;
  int div=radius+radius+1;
  int r[]=new int[wh];
  int g[]=new int[wh];
  int b[]=new int[wh];
  int rsum,gsum,bsum,x,y,i,p,p1,p2,yp,yi,yw;
  int vmin[] = new int[max(w,h)];
  int vmax[] = new int[max(w,h)];
  int[] pix=img.pixels;
  int dv[]=new int[256*div];
  for (i=0;i<256*div;i++){
    dv[i]=(i/div);
  }

  yw=yi=0;

  for (y=0;y<h;y++){
    rsum=gsum=bsum=0;
    for(i=-radius;i<=radius;i++){
      p=pix[yi+min(wm,max(i,0))];
      rsum+=(p & 0xff0000)>>16;
      gsum+=(p & 0x00ff00)>>8;
      bsum+= p & 0x0000ff;
    }
    for (x=0;x<w;x++){

      r[yi]=dv[rsum];
      g[yi]=dv[gsum];
      b[yi]=dv[bsum];

      if(y==0){
        vmin[x]=min(x+radius+1,wm);
        vmax[x]=max(x-radius,0);
      }
      p1=pix[yw+vmin[x]];
      p2=pix[yw+vmax[x]];

      rsum+=((p1 & 0xff0000)-(p2 & 0xff0000))>>16;
      gsum+=((p1 & 0x00ff00)-(p2 & 0x00ff00))>>8;
      bsum+= (p1 & 0x0000ff)-(p2 & 0x0000ff);
      yi++;
    }
    yw+=w;
  }

  for (x=0;x<w;x++){
    rsum=gsum=bsum=0;
    yp=-radius*w;
    for(i=-radius;i<=radius;i++){
      yi=max(0,yp)+x;
      rsum+=r[yi];
      gsum+=g[yi];
      bsum+=b[yi];
      yp+=w;
    }
    yi=x;
    for (y=0;y<h;y++){
      pix[yi]=0xff000000 | (dv[rsum]<<16) | (dv[gsum]<<8) | dv[bsum];
      if(x==0){
        vmin[y]=min(y+radius+1,hm)*w;
        vmax[y]=max(y-radius,0)*w;
      }
      p1=x+vmin[y];
      p2=x+vmax[y];

      rsum+=r[p1]-r[p2];
      gsum+=g[p1]-g[p2];
      bsum+=b[p1]-b[p2];

      yi+=w;
    }
  }

}