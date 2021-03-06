#ifndef PLAYBOX_WORLD_H
#define PLAYBOX_WORLD_H

#include "body.h"
#include "joint.h"
#include "arbiter.h"
#include "maths.h"
#include "array.h"

typedef struct {
  PBVec2 gravity;
  int iterations;
  float pixelScale;
  float angularVelocityDampening;
  
  PBArray* bodies;
  PBArray* joints;
  PBArray* arbiters;
} PBWorld;

extern PBWorld* PBWorldCreate(PBVec2 gravity, int iterations);
extern void PBWorldFree(PBWorld* world);

extern void PBWorldAddBody(PBWorld* world, PBBody* body);
extern void PBWorldRemoveBody(PBWorld* world, PBBody* body);
extern void PBWorldAddJoint(PBWorld* world, PBJoint* joint);
extern void PBWorldRemoveJoint(PBWorld* world, PBJoint* joint);
extern void PBWorldClear(PBWorld* world);
extern void PBWorldStep(PBWorld* world, float dt);
extern void PBWorldBroadphase(PBWorld* world);
extern int PBWorldNumberOfContactsBetweenBodies(PBWorld* world, PBBody* body1, PBBody* body2);

#endif