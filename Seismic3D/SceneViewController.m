//
//  SceneViewController.m
//  Seismic3D
//
//  Created by Biaoqin Wen on 5/25/13.
//  Copyright (c) 2013 Biaoqin Wen. All rights reserved.
//

#import "SceneViewController.h"

#import "SoLogicalViewportElement.h"
#import "SoPerspectiveCamera.h"
#import "SoOrthographicsCamera.h"

#import "SoSeparator.h"
#import "SoCube.h"
#import "SoMaterial.h"
#import "SoTransform.h"
#import "SoDrawStyle.h"
#import "SoDrawStyleElement.h"

@interface SceneViewController () {
    GLKVector3 _anchor_position;
    GLKVector3 _current_position;
    
    GLKQuaternion _quatStart;
    GLKQuaternion _quat;
}

@property (strong, nonatomic) EAGLContext* context;
@property (strong, nonatomic) SoGroup* sceneRoot;

@end

@implementation SceneViewController
@synthesize sceneRoot = _sceneRoot;
@synthesize sceneGraph = _sceneGraph;
@synthesize camera = _camera;
@synthesize viewing = _viewing;
@synthesize autoClipping = _autoClipping;
@synthesize context = _context;

- (void) viewAll
{
    
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!self.context || ![EAGLContext setCurrentContext:self.context]) {
        NSLog(@"Failed to initialize context!");
        exit(-1);
    }
    
    GLKView* sceneView = (GLKView*)self.view;
    sceneView.context = self.context;
    sceneView.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    [self setupGesture];
    [self setupSceneRoot];
    
    _quat = GLKQuaternionMake(0, 0, 0, 1);
    _quatStart = GLKQuaternionMake(0, 0, 0, 1);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)didMoveToParentViewController:(UIViewController *)parent
{
    self.view.frame = parent.view.bounds;
}

#pragma mark - custom methods

- (void) setupGesture
{
    UIPanGestureRecognizer* singlePanGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleSinglePan:)];
    [singlePanGesture setMaximumNumberOfTouches:1];
    [self.view addGestureRecognizer:singlePanGesture];
    
    UIPanGestureRecognizer* doublePanGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoublePan:)];
    [doublePanGesture setMinimumNumberOfTouches:2];
    [self.view addGestureRecognizer:doublePanGesture];
    
    UIPinchGestureRecognizer* pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
    [self.view addGestureRecognizer:pinchGesture];
}

- (void) setupSceneRoot
{
    self.sceneRoot = [[SoGroup alloc] init];
    self.camera = [[SoPerspectiveCamera alloc] init];
    {
        self.camera.aspectRatio = 1.0f;
        self.camera.nearDistance = 0.1f;
        self.camera.farDistance = 100.0f;
        self.camera.position = GLKVector3Make(0, 0, self.camera.focalDistance);
        SoPerspectiveCamera* perspectiveCamera = (SoPerspectiveCamera*)self.camera;
        perspectiveCamera.heightAngle = 45.0f;
    }

    [self.sceneRoot addChild:self.camera];

    SoSeparator* sepNode0 = [[SoSeparator alloc] init];
    {
        SoMaterial* baseMaterial = [[SoMaterial alloc] init];
        baseMaterial.diffuseColor = GLKVector4Make(1, 0.5f, 0.25f, 1.0f);
        [sepNode0 addChild:baseMaterial];
        
        SoTransform* baseTrans = [[SoTransform alloc] init];
        baseTrans.scaleFactor = GLKVector3Make(0.5f, 0.5f, 0.5f);
        [sepNode0 addChild:baseTrans];
        
        [sepNode0 addChild:[[SoCube alloc] init]];
    }
    [self.sceneRoot addChild:sepNode0];
    
    SoSeparator* sepNode1 = [[SoSeparator alloc] init];
    {
        SoMaterial* materialNode = [[SoMaterial alloc] init];
        materialNode.diffuseColor = GLKVector4Make(0.5f, 0.25f, 0, 1.0f);
        [sepNode1 addChild:materialNode];
        
        SoTransform* transNode = [[SoTransform alloc] init];
        transNode.scaleFactor = GLKVector3Make(0.2f, 1, 1);
        [sepNode1 addChild:transNode];
        
        [sepNode1 addChild:[[SoCube alloc] init]];
        
    }
    [self.sceneRoot addChild:sepNode1];
}

#pragma mark - GLKView & GLKViewController delegate Methods

- (void)update
{
    [[SoLogicalViewportElement sharedInstance] setSize:self.view.bounds.size];
    
    if (self.camera) {
        GLKVector3 dir = GLKQuaternionRotateVector3(self.camera.orientation, GLKVector3Make(0, 0, -1));
        dir = GLKVector3MultiplyScalar(GLKVector3Normalize(dir), self.camera.focalDistance);
        GLKVector3 focalPoint = GLKVector3Add(self.camera.position, dir);
        
        self.camera.orientation = GLKQuaternionInvert(_quat);
        dir = GLKQuaternionRotateVector3(self.camera.orientation, GLKVector3Make(0, 0, -1));
        dir = GLKVector3MultiplyScalar(GLKVector3Normalize(dir), self.camera.focalDistance);
        self.camera.position = GLKVector3Subtract(focalPoint, dir);
        
//        self.camera.orientation = GLKQuaternionInvert(_quat);
//        self.camera.position = GLKQuaternionRotateVector3(self.camera.orientation, GLKVector3Make(0, 0, self.camera.focalDistance));
    }
    
    [self.sceneRoot update];
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    glClearColor(0, 104.0/255.0, 50.0/255.0, 1);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    [self.sceneRoot render];
}

#pragma mark - ArcBall operation

- (GLKVector3)projectOntoSurface:(GLKVector3)touchPoint
{
    float radius = self.view.bounds.size.width / 2;
    GLKVector3 P = touchPoint;
    
    P = GLKVector3Make(P.x, P.y * -1, P.z);
    
    float radius2 = radius * radius;
    float length2 = P.x*P.x + P.y*P.y;
    
    if (length2 <= radius2) {
        P.z = sqrtf(radius2 - length2);
    } else {
        P.x *= radius / sqrtf(length2);
        P.y *= radius / sqrtf(length2);
        P.z = 0;
    }
    
    return GLKVector3Normalize(P);
}

- (void)computeIncremental
{
    GLKVector3 axis = GLKVector3CrossProduct(_anchor_position, _current_position);
    float dot = GLKVector3DotProduct(_anchor_position, _current_position);
    float angle = acosf(dot);
    
    GLKQuaternion Q_rot = GLKQuaternionMakeWithAngleAndVector3Axis(angle*2, axis);
    Q_rot = GLKQuaternionNormalize(Q_rot);
    
    _quat = GLKQuaternionMultiply(Q_rot, _quatStart);
}

#pragma mark - GestureRecognizer methods

- (void) handleSinglePan: (UIPanGestureRecognizer*) recognizer
{
    CGPoint location = [recognizer translationInView:self.view];
    
    switch ([recognizer state]) {
        case UIGestureRecognizerStateBegan: {
            _anchor_position = GLKVector3Make(location.x, location.y, 0);
            _anchor_position = [self projectOntoSurface:_anchor_position];
            _current_position = _anchor_position;
            
            _quatStart = _quat;
        } break;
            
        case UIGestureRecognizerStateChanged: {
            _current_position = GLKVector3Make(location.x, location.y, 0);
            _current_position = [self projectOntoSurface:_current_position];
            
            [self computeIncremental];
            
        } break;
            
        default: break;
    }
}

- (void) handleDoublePan:(UIPanGestureRecognizer*) recognizer
{
    switch ([recognizer state]) {
        case UIGestureRecognizerStateBegan: {
        } break;
            
        case UIGestureRecognizerStateChanged: {
        } break;
            
        default: break;
    }
}

- (void) handlePinch: (UIPinchGestureRecognizer*) recognizer
{
    if (self.camera) {
        self.camera.focalDistance = self.camera.focalDistance * (1.0/recognizer.scale);
    }
    recognizer.scale = 1.0f;
}

@end
