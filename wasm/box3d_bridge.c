#include <box3d/box3d.h>
#include <box3d/collision.h>

#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

#ifdef __EMSCRIPTEN__
#define B3D_EXPORT
#else
#define B3D_EXPORT
#endif

typedef struct b3d_State
{
    b3WorldId* worlds;
    int worldCount;
    int worldCapacity;

    b3BodyId* bodies;
    int bodyCount;
    int bodyCapacity;

    b3ShapeId* shapes;
    int shapeCount;
    int shapeCapacity;
} b3d_State;

static b3d_State b3d_state;

static bool b3d_reserve(void** data, int* capacity, int count, size_t elementSize)
{
    if (count <= *capacity)
    {
        return true;
    }

    int newCapacity = *capacity == 0 ? 64 : *capacity * 2;
    while (newCapacity < count)
    {
        newCapacity *= 2;
    }

    void* newData = realloc(*data, (size_t)newCapacity * elementSize);
    if (newData == NULL)
    {
        return false;
    }

    *data = newData;
    *capacity = newCapacity;
    return true;
}

static int b3d_store_world(b3WorldId id)
{
    if (B3_IS_NULL(id) || !b3d_reserve((void**)&b3d_state.worlds, &b3d_state.worldCapacity, b3d_state.worldCount + 1, sizeof(b3WorldId)))
    {
        return 0;
    }

    b3d_state.worlds[b3d_state.worldCount] = id;
    b3d_state.worldCount += 1;
    return b3d_state.worldCount;
}

static int b3d_store_body(b3BodyId id)
{
    if (B3_IS_NULL(id) || !b3d_reserve((void**)&b3d_state.bodies, &b3d_state.bodyCapacity, b3d_state.bodyCount + 1, sizeof(b3BodyId)))
    {
        return 0;
    }

    b3d_state.bodies[b3d_state.bodyCount] = id;
    b3d_state.bodyCount += 1;
    return b3d_state.bodyCount;
}

static int b3d_store_shape(b3ShapeId id)
{
    if (B3_IS_NULL(id) || !b3d_reserve((void**)&b3d_state.shapes, &b3d_state.shapeCapacity, b3d_state.shapeCount + 1, sizeof(b3ShapeId)))
    {
        return 0;
    }

    b3d_state.shapes[b3d_state.shapeCount] = id;
    b3d_state.shapeCount += 1;
    return b3d_state.shapeCount;
}

static b3WorldId b3d_get_world(int handle)
{
    if (handle <= 0 || handle > b3d_state.worldCount)
    {
        return b3_nullWorldId;
    }

    b3WorldId id = b3d_state.worlds[handle - 1];
    return b3World_IsValid(id) ? id : b3_nullWorldId;
}

static b3BodyId b3d_get_body(int handle)
{
    if (handle <= 0 || handle > b3d_state.bodyCount)
    {
        return b3_nullBodyId;
    }

    b3BodyId id = b3d_state.bodies[handle - 1];
    return b3Body_IsValid(id) ? id : b3_nullBodyId;
}

static b3ShapeId b3d_get_shape(int handle)
{
    if (handle <= 0 || handle > b3d_state.shapeCount)
    {
        return b3_nullShapeId;
    }

    b3ShapeId id = b3d_state.shapes[handle - 1];
    return b3Shape_IsValid(id) ? id : b3_nullShapeId;
}

B3D_EXPORT int b3d_create_world(float gravityX, float gravityY, float gravityZ)
{
    b3WorldDef def = b3DefaultWorldDef();
    def.gravity = (b3Vec3){gravityX, gravityY, gravityZ};
    def.workerCount = 1;

    return b3d_store_world(b3CreateWorld(&def));
}

B3D_EXPORT void b3d_destroy_world(int worldHandle)
{
    b3WorldId worldId = b3d_get_world(worldHandle);
    if (B3_IS_NON_NULL(worldId))
    {
        b3DestroyWorld(worldId);
        b3d_state.worlds[worldHandle - 1] = b3_nullWorldId;
    }
}

B3D_EXPORT void b3d_step(int worldHandle, float timeStep, int subStepCount)
{
    b3WorldId worldId = b3d_get_world(worldHandle);
    if (B3_IS_NON_NULL(worldId))
    {
        b3World_Step(worldId, timeStep, subStepCount);
    }
}

B3D_EXPORT int b3d_create_body(int worldHandle, int bodyType, float x, float y, float z, float qx, float qy, float qz, float qw)
{
    b3WorldId worldId = b3d_get_world(worldHandle);
    if (B3_IS_NULL(worldId))
    {
        return 0;
    }

    if (bodyType < b3_staticBody || bodyType >= b3_bodyTypeCount)
    {
        return 0;
    }

    b3BodyDef def = b3DefaultBodyDef();
    def.type = (b3BodyType)bodyType;
    def.position = (b3Pos){x, y, z};
    def.rotation = (b3Quat){{qx, qy, qz}, qw};

    return b3d_store_body(b3CreateBody(worldId, &def));
}

B3D_EXPORT void b3d_destroy_body(int bodyHandle)
{
    b3BodyId bodyId = b3d_get_body(bodyHandle);
    if (B3_IS_NON_NULL(bodyId))
    {
        b3DestroyBody(bodyId);
        b3d_state.bodies[bodyHandle - 1] = b3_nullBodyId;
    }
}

static b3ShapeDef b3d_shape_def(float density, float friction, float restitution)
{
    b3ShapeDef def = b3DefaultShapeDef();
    def.density = density;
    def.baseMaterial.friction = friction;
    def.baseMaterial.restitution = restitution;
    return def;
}

B3D_EXPORT int b3d_create_sphere(int bodyHandle, float radius, float density, float friction, float restitution)
{
    b3BodyId bodyId = b3d_get_body(bodyHandle);
    if (B3_IS_NULL(bodyId) || radius <= 0.0f)
    {
        return 0;
    }

    b3ShapeDef def = b3d_shape_def(density, friction, restitution);
    b3Sphere sphere = {{0.0f, 0.0f, 0.0f}, radius};
    return b3d_store_shape(b3CreateSphereShape(bodyId, &def, &sphere));
}

B3D_EXPORT int b3d_create_capsule(int bodyHandle, float ax, float ay, float az, float bx, float by, float bz, float radius, float density, float friction, float restitution)
{
    b3BodyId bodyId = b3d_get_body(bodyHandle);
    if (B3_IS_NULL(bodyId) || radius <= 0.0f)
    {
        return 0;
    }

    b3ShapeDef def = b3d_shape_def(density, friction, restitution);
    b3Capsule capsule = {{ax, ay, az}, {bx, by, bz}, radius};
    return b3d_store_shape(b3CreateCapsuleShape(bodyId, &def, &capsule));
}

B3D_EXPORT int b3d_create_box(int bodyHandle, float hx, float hy, float hz, float density, float friction, float restitution)
{
    b3BodyId bodyId = b3d_get_body(bodyHandle);
    if (B3_IS_NULL(bodyId) || hx <= 0.0f || hy <= 0.0f || hz <= 0.0f)
    {
        return 0;
    }

    b3ShapeDef def = b3d_shape_def(density, friction, restitution);
    b3BoxHull box = b3MakeBoxHull(hx, hy, hz);
    return b3d_store_shape(b3CreateHullShape(bodyId, &def, &box.base));
}

B3D_EXPORT void b3d_destroy_shape(int shapeHandle)
{
    b3ShapeId shapeId = b3d_get_shape(shapeHandle);
    if (B3_IS_NON_NULL(shapeId))
    {
        b3DestroyShape(shapeId, true);
        b3d_state.shapes[shapeHandle - 1] = b3_nullShapeId;
    }
}

B3D_EXPORT void b3d_get_body_transform(int bodyHandle, float* outTransform)
{
    if (outTransform == NULL)
    {
        return;
    }

    b3BodyId bodyId = b3d_get_body(bodyHandle);
    if (B3_IS_NULL(bodyId))
    {
        for (int i = 0; i < 7; ++i)
        {
            outTransform[i] = 0.0f;
        }
        outTransform[6] = 1.0f;
        return;
    }

    b3WorldTransform transform = b3Body_GetTransform(bodyId);
    outTransform[0] = (float)transform.p.x;
    outTransform[1] = (float)transform.p.y;
    outTransform[2] = (float)transform.p.z;
    outTransform[3] = transform.q.v.x;
    outTransform[4] = transform.q.v.y;
    outTransform[5] = transform.q.v.z;
    outTransform[6] = transform.q.s;
}

B3D_EXPORT void b3d_set_body_transform(int bodyHandle, float x, float y, float z, float qx, float qy, float qz, float qw)
{
    b3BodyId bodyId = b3d_get_body(bodyHandle);
    if (B3_IS_NON_NULL(bodyId))
    {
        b3Body_SetTransform(bodyId, (b3Pos){x, y, z}, (b3Quat){{qx, qy, qz}, qw});
    }
}

B3D_EXPORT void b3d_get_body_linear_velocity(int bodyHandle, float* outVelocity)
{
    if (outVelocity == NULL)
    {
        return;
    }

    b3BodyId bodyId = b3d_get_body(bodyHandle);
    if (B3_IS_NULL(bodyId))
    {
        outVelocity[0] = 0.0f;
        outVelocity[1] = 0.0f;
        outVelocity[2] = 0.0f;
        return;
    }

    b3Vec3 velocity = b3Body_GetLinearVelocity(bodyId);
    outVelocity[0] = velocity.x;
    outVelocity[1] = velocity.y;
    outVelocity[2] = velocity.z;
}

B3D_EXPORT void b3d_set_body_linear_velocity(int bodyHandle, float x, float y, float z)
{
    b3BodyId bodyId = b3d_get_body(bodyHandle);
    if (B3_IS_NON_NULL(bodyId))
    {
        b3Body_SetLinearVelocity(bodyId, (b3Vec3){x, y, z});
    }
}
