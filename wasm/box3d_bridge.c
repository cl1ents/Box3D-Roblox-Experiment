#include <box3d/box3d.h>
#include <box3d/collision.h>

#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#define B3D_EXPORT
#define B3D_MAX_QUERY_RESULTS 256
#define B3D_MAX_EVENT_RESULTS 512

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

    b3JointId* joints;
    int jointCount;
    int jointCapacity;

    b3ShapeId queryShapes[B3D_MAX_QUERY_RESULTS];
    b3Vec3 queryPoints[B3D_MAX_QUERY_RESULTS];
    b3Vec3 queryNormals[B3D_MAX_QUERY_RESULTS];
    float queryFractions[B3D_MAX_QUERY_RESULTS];
    int queryCount;
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

#define B3D_STORE(kind, field, Type, nullValue) \
static int b3d_store_##kind(Type id) \
{ \
    if (B3_IS_NULL(id)) \
    { \
        return 0; \
    } \
    for (int i = 0; i < b3d_state.kind##Count; ++i) \
    { \
        if (memcmp(&b3d_state.field[i], &id, sizeof(Type)) == 0) \
        { \
            return i + 1; \
        } \
    } \
    if (!b3d_reserve((void**)&b3d_state.field, &b3d_state.kind##Capacity, b3d_state.kind##Count + 1, sizeof(Type))) \
    { \
        return 0; \
    } \
    b3d_state.field[b3d_state.kind##Count] = id; \
    b3d_state.kind##Count += 1; \
    return b3d_state.kind##Count; \
}

B3D_STORE(world, worlds, b3WorldId, b3_nullWorldId)
B3D_STORE(body, bodies, b3BodyId, b3_nullBodyId)
B3D_STORE(shape, shapes, b3ShapeId, b3_nullShapeId)
B3D_STORE(joint, joints, b3JointId, b3_nullJointId)

B3D_EXPORT int b3d_create_sphere_ex(int bodyHandle, float cx, float cy, float cz, float radius, float density, float friction, float restitution, int isSensor, int categoryBits, int maskBits, int groupIndex);

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

static b3JointId b3d_get_joint(int handle)
{
    if (handle <= 0 || handle > b3d_state.jointCount)
    {
        return b3_nullJointId;
    }

    b3JointId id = b3d_state.joints[handle - 1];
    return b3Joint_IsValid(id) ? id : b3_nullJointId;
}

static b3Vec3 b3d_vec3(float x, float y, float z)
{
    return (b3Vec3){x, y, z};
}

static b3Quat b3d_quat(float x, float y, float z, float w)
{
    return (b3Quat){{x, y, z}, w};
}

static b3Transform b3d_transform(float px, float py, float pz, float qx, float qy, float qz, float qw)
{
    return (b3Transform){b3d_vec3(px, py, pz), b3d_quat(qx, qy, qz, qw)};
}

static b3ShapeDef b3d_shape_def(float density, float friction, float restitution, int isSensor, int categoryBits, int maskBits, int groupIndex)
{
    b3ShapeDef def = b3DefaultShapeDef();
    def.density = density;
    def.baseMaterial.friction = friction;
    def.baseMaterial.restitution = restitution;
    def.isSensor = isSensor != 0;
    def.filter.categoryBits = (uint64_t)(uint32_t)categoryBits;
    def.filter.maskBits = (uint64_t)(uint32_t)maskBits;
    def.filter.groupIndex = groupIndex;
    return def;
}

static b3QueryFilter b3d_query_filter(int categoryBits, int maskBits)
{
    b3QueryFilter filter = b3DefaultQueryFilter();
    filter.categoryBits = (uint64_t)(uint32_t)categoryBits;
    filter.maskBits = (uint64_t)(uint32_t)maskBits;
    return filter;
}

static void b3d_write_vec3(float* out, b3Vec3 v)
{
    if (out == NULL) { return; }
    out[0] = v.x;
    out[1] = v.y;
    out[2] = v.z;
}

static void b3d_write_quat(float* out, b3Quat q)
{
    if (out == NULL) { return; }
    out[0] = q.v.x;
    out[1] = q.v.y;
    out[2] = q.v.z;
    out[3] = q.s;
}

static void b3d_write_transform(float* out, b3WorldTransform transform)
{
    if (out == NULL) { return; }
    out[0] = (float)transform.p.x;
    out[1] = (float)transform.p.y;
    out[2] = (float)transform.p.z;
    out[3] = transform.q.v.x;
    out[4] = transform.q.v.y;
    out[5] = transform.q.v.z;
    out[6] = transform.q.s;
}

static void b3d_write_aabb(float* out, b3AABB aabb)
{
    if (out == NULL) { return; }
    out[0] = aabb.lowerBound.x;
    out[1] = aabb.lowerBound.y;
    out[2] = aabb.lowerBound.z;
    out[3] = aabb.upperBound.x;
    out[4] = aabb.upperBound.y;
    out[5] = aabb.upperBound.z;
}

static void b3d_write_mass(float* out, b3MassData mass)
{
    if (out == NULL) { return; }
    out[0] = mass.mass;
    out[1] = mass.center.x;
    out[2] = mass.center.y;
    out[3] = mass.center.z;
    out[4] = mass.inertia.cx.x;
    out[5] = mass.inertia.cx.y;
    out[6] = mass.inertia.cx.z;
    out[7] = mass.inertia.cy.x;
    out[8] = mass.inertia.cy.y;
    out[9] = mass.inertia.cy.z;
    out[10] = mass.inertia.cz.x;
    out[11] = mass.inertia.cz.y;
    out[12] = mass.inertia.cz.z;
}

static void b3d_write_ray_result(float* out, int* outShape, b3RayResult result)
{
    if (outShape != NULL) { outShape[0] = result.hit ? b3d_store_shape(result.shapeId) : 0; }
    if (out == NULL) { return; }
    out[0] = result.hit ? 1.0f : 0.0f;
    out[1] = (float)result.point.x;
    out[2] = (float)result.point.y;
    out[3] = (float)result.point.z;
    out[4] = result.normal.x;
    out[5] = result.normal.y;
    out[6] = result.normal.z;
    out[7] = result.fraction;
    out[8] = (float)result.triangleIndex;
    out[9] = (float)result.childIndex;
    out[10] = (float)result.nodeVisits;
    out[11] = (float)result.leafVisits;
}

static void b3d_write_cast_output(float* out, b3WorldCastOutput result)
{
    if (out == NULL) { return; }
    out[0] = result.hit ? 1.0f : 0.0f;
    out[1] = result.point.x;
    out[2] = result.point.y;
    out[3] = result.point.z;
    out[4] = result.normal.x;
    out[5] = result.normal.y;
    out[6] = result.normal.z;
    out[7] = result.fraction;
    out[8] = (float)result.iterations;
    out[9] = (float)result.triangleIndex;
    out[10] = (float)result.childIndex;
    out[11] = (float)result.materialIndex;
}

static bool b3d_overlap_callback(b3ShapeId shapeId, void* context)
{
    (void)context;
    if (b3d_state.queryCount >= B3D_MAX_QUERY_RESULTS)
    {
        return false;
    }

    b3d_state.queryShapes[b3d_state.queryCount] = shapeId;
    b3d_state.queryCount += 1;
    return true;
}

static float b3d_cast_callback(b3ShapeId shapeId, b3Pos point, b3Vec3 normal, float fraction, uint64_t materialBits, int triangleIndex, int childIndex, void* context)
{
    (void)context;
    (void)materialBits;
    (void)triangleIndex;
    (void)childIndex;
    if (b3d_state.queryCount >= B3D_MAX_QUERY_RESULTS)
    {
        return fraction;
    }

    int index = b3d_state.queryCount;
    b3d_state.queryShapes[index] = shapeId;
    b3d_state.queryPoints[index] = point;
    b3d_state.queryNormals[index] = normal;
    b3d_state.queryFractions[index] = fraction;
    b3d_state.queryCount += 1;
    return 1.0f;
}

B3D_EXPORT int b3d_create_world(float gravityX, float gravityY, float gravityZ)
{
    b3WorldDef def = b3DefaultWorldDef();
    def.gravity = b3d_vec3(gravityX, gravityY, gravityZ);
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

B3D_EXPORT int b3d_get_world_count(void) { return b3GetWorldCount(); }
B3D_EXPORT int b3d_get_max_world_count(void) { return b3GetMaxWorldCount(); }
B3D_EXPORT int b3d_world_is_valid(int worldHandle) { return B3_IS_NON_NULL(b3d_get_world(worldHandle)); }

B3D_EXPORT void b3d_step(int worldHandle, float timeStep, int subStepCount)
{
    b3WorldId worldId = b3d_get_world(worldHandle);
    if (B3_IS_NON_NULL(worldId)) { b3World_Step(worldId, timeStep, subStepCount); }
}

B3D_EXPORT void b3d_world_get_bounds(int worldHandle, float* outAabb)
{
    b3WorldId worldId = b3d_get_world(worldHandle);
    b3d_write_aabb(outAabb, B3_IS_NON_NULL(worldId) ? b3World_GetBounds(worldId) : (b3AABB){0});
}

B3D_EXPORT void b3d_world_set_gravity(int worldHandle, float x, float y, float z)
{
    b3WorldId worldId = b3d_get_world(worldHandle);
    if (B3_IS_NON_NULL(worldId)) { b3World_SetGravity(worldId, b3d_vec3(x, y, z)); }
}

B3D_EXPORT void b3d_world_get_gravity(int worldHandle, float* out)
{
    b3WorldId worldId = b3d_get_world(worldHandle);
    b3d_write_vec3(out, B3_IS_NON_NULL(worldId) ? b3World_GetGravity(worldId) : b3d_vec3(0.0f, 0.0f, 0.0f));
}

B3D_EXPORT void b3d_world_enable_sleeping(int worldHandle, int flag)
{
    b3WorldId worldId = b3d_get_world(worldHandle);
    if (B3_IS_NON_NULL(worldId)) { b3World_EnableSleeping(worldId, flag != 0); }
}

B3D_EXPORT int b3d_world_is_sleeping_enabled(int worldHandle)
{
    b3WorldId worldId = b3d_get_world(worldHandle);
    return B3_IS_NON_NULL(worldId) && b3World_IsSleepingEnabled(worldId);
}

B3D_EXPORT void b3d_world_enable_continuous(int worldHandle, int flag)
{
    b3WorldId worldId = b3d_get_world(worldHandle);
    if (B3_IS_NON_NULL(worldId)) { b3World_EnableContinuous(worldId, flag != 0); }
}

B3D_EXPORT int b3d_world_is_continuous_enabled(int worldHandle)
{
    b3WorldId worldId = b3d_get_world(worldHandle);
    return B3_IS_NON_NULL(worldId) && b3World_IsContinuousEnabled(worldId);
}

B3D_EXPORT void b3d_world_set_restitution_threshold(int worldHandle, float value)
{
    b3WorldId worldId = b3d_get_world(worldHandle);
    if (B3_IS_NON_NULL(worldId)) { b3World_SetRestitutionThreshold(worldId, value); }
}

B3D_EXPORT float b3d_world_get_restitution_threshold(int worldHandle)
{
    b3WorldId worldId = b3d_get_world(worldHandle);
    return B3_IS_NON_NULL(worldId) ? b3World_GetRestitutionThreshold(worldId) : 0.0f;
}

B3D_EXPORT void b3d_world_set_hit_event_threshold(int worldHandle, float value)
{
    b3WorldId worldId = b3d_get_world(worldHandle);
    if (B3_IS_NON_NULL(worldId)) { b3World_SetHitEventThreshold(worldId, value); }
}

B3D_EXPORT float b3d_world_get_hit_event_threshold(int worldHandle)
{
    b3WorldId worldId = b3d_get_world(worldHandle);
    return B3_IS_NON_NULL(worldId) ? b3World_GetHitEventThreshold(worldId) : 0.0f;
}

B3D_EXPORT void b3d_world_set_contact_tuning(int worldHandle, float hertz, float dampingRatio, float contactSpeed)
{
    b3WorldId worldId = b3d_get_world(worldHandle);
    if (B3_IS_NON_NULL(worldId)) { b3World_SetContactTuning(worldId, hertz, dampingRatio, contactSpeed); }
}

B3D_EXPORT void b3d_world_set_maximum_linear_speed(int worldHandle, float speed)
{
    b3WorldId worldId = b3d_get_world(worldHandle);
    if (B3_IS_NON_NULL(worldId)) { b3World_SetMaximumLinearSpeed(worldId, speed); }
}

B3D_EXPORT float b3d_world_get_maximum_linear_speed(int worldHandle)
{
    b3WorldId worldId = b3d_get_world(worldHandle);
    return B3_IS_NON_NULL(worldId) ? b3World_GetMaximumLinearSpeed(worldId) : 0.0f;
}

B3D_EXPORT int b3d_world_get_awake_body_count(int worldHandle)
{
    b3WorldId worldId = b3d_get_world(worldHandle);
    return B3_IS_NON_NULL(worldId) ? b3World_GetAwakeBodyCount(worldId) : 0;
}

B3D_EXPORT void b3d_world_get_counters(int worldHandle, int* out)
{
    if (out == NULL) { return; }
    memset(out, 0, sizeof(int) * 16);
    b3WorldId worldId = b3d_get_world(worldHandle);
    if (B3_IS_NULL(worldId)) { return; }
    b3Counters c = b3World_GetCounters(worldId);
    out[0] = c.bodyCount; out[1] = c.shapeCount; out[2] = c.contactCount; out[3] = c.jointCount;
    out[4] = c.islandCount; out[5] = c.stackUsed; out[6] = c.arenaCapacity; out[7] = c.staticTreeHeight;
    out[8] = c.treeHeight; out[9] = c.byteCount; out[10] = c.taskCount; out[11] = c.awakeContactCount;
    out[12] = c.recycledContactCount; out[13] = c.distanceIterations; out[14] = c.pushBackIterations; out[15] = c.rootIterations;
}

B3D_EXPORT void b3d_world_get_profile(int worldHandle, float* out)
{
    if (out == NULL) { return; }
    memset(out, 0, sizeof(float) * 24);
    b3WorldId worldId = b3d_get_world(worldHandle);
    if (B3_IS_NULL(worldId)) { return; }
    b3Profile p = b3World_GetProfile(worldId);
    out[0] = p.step; out[1] = p.pairs; out[2] = p.collide; out[3] = p.solve; out[4] = p.solverSetup;
    out[5] = p.constraints; out[6] = p.prepareConstraints; out[7] = p.integrateVelocities; out[8] = p.warmStart;
    out[9] = p.solveImpulses; out[10] = p.integratePositions; out[11] = p.relaxImpulses; out[12] = p.applyRestitution;
    out[13] = p.storeImpulses; out[14] = p.splitIslands; out[15] = p.transforms; out[16] = p.sensorHits;
    out[17] = p.jointEvents; out[18] = p.hitEvents; out[19] = p.refit; out[20] = p.bullets; out[21] = p.sleepIslands; out[22] = p.sensors;
}

B3D_EXPORT void b3d_world_explode(int worldHandle, float x, float y, float z, float radius, float falloff, float impulsePerArea, int maskBits)
{
    b3WorldId worldId = b3d_get_world(worldHandle);
    if (B3_IS_NULL(worldId)) { return; }
    b3ExplosionDef def = b3DefaultExplosionDef();
    def.position = (b3Pos){x, y, z};
    def.radius = radius;
    def.falloff = falloff;
    def.impulsePerArea = impulsePerArea;
    def.maskBits = (uint64_t)(uint32_t)maskBits;
    b3World_Explode(worldId, &def);
}

B3D_EXPORT int b3d_create_body(int worldHandle, int bodyType, float x, float y, float z, float qx, float qy, float qz, float qw)
{
    b3WorldId worldId = b3d_get_world(worldHandle);
    if (B3_IS_NULL(worldId) || bodyType < b3_staticBody || bodyType >= b3_bodyTypeCount) { return 0; }
    b3BodyDef def = b3DefaultBodyDef();
    def.type = (b3BodyType)bodyType;
    def.position = (b3Pos){x, y, z};
    def.rotation = b3d_quat(qx, qy, qz, qw);
    return b3d_store_body(b3CreateBody(worldId, &def));
}

B3D_EXPORT void b3d_destroy_body(int bodyHandle)
{
    b3BodyId bodyId = b3d_get_body(bodyHandle);
    if (B3_IS_NON_NULL(bodyId)) { b3DestroyBody(bodyId); b3d_state.bodies[bodyHandle - 1] = b3_nullBodyId; }
}

B3D_EXPORT int b3d_body_is_valid(int bodyHandle) { return B3_IS_NON_NULL(b3d_get_body(bodyHandle)); }
B3D_EXPORT int b3d_body_get_type(int bodyHandle) { b3BodyId id = b3d_get_body(bodyHandle); return B3_IS_NON_NULL(id) ? (int)b3Body_GetType(id) : -1; }
B3D_EXPORT void b3d_body_set_type(int bodyHandle, int type) { b3BodyId id = b3d_get_body(bodyHandle); if (B3_IS_NON_NULL(id) && type >= 0 && type < b3_bodyTypeCount) { b3Body_SetType(id, (b3BodyType)type); } }

B3D_EXPORT void b3d_get_body_transform(int bodyHandle, float* outTransform)
{
    b3BodyId id = b3d_get_body(bodyHandle);
    b3d_write_transform(outTransform, B3_IS_NON_NULL(id) ? b3Body_GetTransform(id) : (b3WorldTransform){0});
    if (B3_IS_NULL(id) && outTransform != NULL) { outTransform[6] = 1.0f; }
}

B3D_EXPORT void b3d_set_body_transform(int bodyHandle, float x, float y, float z, float qx, float qy, float qz, float qw)
{
    b3BodyId id = b3d_get_body(bodyHandle);
    if (B3_IS_NON_NULL(id)) { b3Body_SetTransform(id, (b3Pos){x, y, z}, b3d_quat(qx, qy, qz, qw)); }
}

B3D_EXPORT void b3d_body_get_position(int bodyHandle, float* out) { b3BodyId id = b3d_get_body(bodyHandle); b3d_write_vec3(out, B3_IS_NON_NULL(id) ? b3Body_GetPosition(id) : b3d_vec3(0, 0, 0)); }
B3D_EXPORT void b3d_body_get_rotation(int bodyHandle, float* out) { b3BodyId id = b3d_get_body(bodyHandle); b3d_write_quat(out, B3_IS_NON_NULL(id) ? b3Body_GetRotation(id) : b3d_quat(0, 0, 0, 1)); }
B3D_EXPORT void b3d_get_body_linear_velocity(int bodyHandle, float* out) { b3BodyId id = b3d_get_body(bodyHandle); b3d_write_vec3(out, B3_IS_NON_NULL(id) ? b3Body_GetLinearVelocity(id) : b3d_vec3(0, 0, 0)); }
B3D_EXPORT void b3d_set_body_linear_velocity(int bodyHandle, float x, float y, float z) { b3BodyId id = b3d_get_body(bodyHandle); if (B3_IS_NON_NULL(id)) { b3Body_SetLinearVelocity(id, b3d_vec3(x, y, z)); } }
B3D_EXPORT void b3d_body_get_angular_velocity(int bodyHandle, float* out) { b3BodyId id = b3d_get_body(bodyHandle); b3d_write_vec3(out, B3_IS_NON_NULL(id) ? b3Body_GetAngularVelocity(id) : b3d_vec3(0, 0, 0)); }
B3D_EXPORT void b3d_body_set_angular_velocity(int bodyHandle, float x, float y, float z) { b3BodyId id = b3d_get_body(bodyHandle); if (B3_IS_NON_NULL(id)) { b3Body_SetAngularVelocity(id, b3d_vec3(x, y, z)); } }
B3D_EXPORT void b3d_body_apply_force(int bodyHandle, float fx, float fy, float fz, float px, float py, float pz, int wake) { b3BodyId id = b3d_get_body(bodyHandle); if (B3_IS_NON_NULL(id)) { b3Body_ApplyForce(id, b3d_vec3(fx, fy, fz), (b3Pos){px, py, pz}, wake != 0); } }
B3D_EXPORT void b3d_body_apply_force_to_center(int bodyHandle, float fx, float fy, float fz, int wake) { b3BodyId id = b3d_get_body(bodyHandle); if (B3_IS_NON_NULL(id)) { b3Body_ApplyForceToCenter(id, b3d_vec3(fx, fy, fz), wake != 0); } }
B3D_EXPORT void b3d_body_apply_torque(int bodyHandle, float x, float y, float z, int wake) { b3BodyId id = b3d_get_body(bodyHandle); if (B3_IS_NON_NULL(id)) { b3Body_ApplyTorque(id, b3d_vec3(x, y, z), wake != 0); } }
B3D_EXPORT void b3d_body_apply_linear_impulse(int bodyHandle, float ix, float iy, float iz, float px, float py, float pz, int wake) { b3BodyId id = b3d_get_body(bodyHandle); if (B3_IS_NON_NULL(id)) { b3Body_ApplyLinearImpulse(id, b3d_vec3(ix, iy, iz), (b3Pos){px, py, pz}, wake != 0); } }
B3D_EXPORT void b3d_body_apply_linear_impulse_to_center(int bodyHandle, float x, float y, float z, int wake) { b3BodyId id = b3d_get_body(bodyHandle); if (B3_IS_NON_NULL(id)) { b3Body_ApplyLinearImpulseToCenter(id, b3d_vec3(x, y, z), wake != 0); } }
B3D_EXPORT void b3d_body_apply_angular_impulse(int bodyHandle, float x, float y, float z, int wake) { b3BodyId id = b3d_get_body(bodyHandle); if (B3_IS_NON_NULL(id)) { b3Body_ApplyAngularImpulse(id, b3d_vec3(x, y, z), wake != 0); } }
B3D_EXPORT float b3d_body_get_mass(int bodyHandle) { b3BodyId id = b3d_get_body(bodyHandle); return B3_IS_NON_NULL(id) ? b3Body_GetMass(id) : 0.0f; }
B3D_EXPORT float b3d_body_get_inverse_mass(int bodyHandle) { b3BodyId id = b3d_get_body(bodyHandle); return B3_IS_NON_NULL(id) ? b3Body_GetInverseMass(id) : 0.0f; }
B3D_EXPORT void b3d_body_get_mass_data(int bodyHandle, float* out) { b3BodyId id = b3d_get_body(bodyHandle); b3d_write_mass(out, B3_IS_NON_NULL(id) ? b3Body_GetMassData(id) : (b3MassData){0}); }
B3D_EXPORT void b3d_body_set_mass_data(int bodyHandle, float mass, float cx, float cy, float cz, float ixx, float iyy, float izz) { b3BodyId id = b3d_get_body(bodyHandle); if (B3_IS_NON_NULL(id)) { b3MassData m = {0}; m.mass = mass; m.center = b3d_vec3(cx, cy, cz); m.inertia.cx.x = ixx; m.inertia.cy.y = iyy; m.inertia.cz.z = izz; b3Body_SetMassData(id, m); } }
B3D_EXPORT void b3d_body_apply_mass_from_shapes(int bodyHandle) { b3BodyId id = b3d_get_body(bodyHandle); if (B3_IS_NON_NULL(id)) { b3Body_ApplyMassFromShapes(id); } }
B3D_EXPORT void b3d_body_set_linear_damping(int bodyHandle, float v) { b3BodyId id = b3d_get_body(bodyHandle); if (B3_IS_NON_NULL(id)) { b3Body_SetLinearDamping(id, v); } }
B3D_EXPORT float b3d_body_get_linear_damping(int bodyHandle) { b3BodyId id = b3d_get_body(bodyHandle); return B3_IS_NON_NULL(id) ? b3Body_GetLinearDamping(id) : 0.0f; }
B3D_EXPORT void b3d_body_set_angular_damping(int bodyHandle, float v) { b3BodyId id = b3d_get_body(bodyHandle); if (B3_IS_NON_NULL(id)) { b3Body_SetAngularDamping(id, v); } }
B3D_EXPORT float b3d_body_get_angular_damping(int bodyHandle) { b3BodyId id = b3d_get_body(bodyHandle); return B3_IS_NON_NULL(id) ? b3Body_GetAngularDamping(id) : 0.0f; }
B3D_EXPORT void b3d_body_set_gravity_scale(int bodyHandle, float v) { b3BodyId id = b3d_get_body(bodyHandle); if (B3_IS_NON_NULL(id)) { b3Body_SetGravityScale(id, v); } }
B3D_EXPORT float b3d_body_get_gravity_scale(int bodyHandle) { b3BodyId id = b3d_get_body(bodyHandle); return B3_IS_NON_NULL(id) ? b3Body_GetGravityScale(id) : 0.0f; }
B3D_EXPORT int b3d_body_is_awake(int bodyHandle) { b3BodyId id = b3d_get_body(bodyHandle); return B3_IS_NON_NULL(id) && b3Body_IsAwake(id); }
B3D_EXPORT void b3d_body_set_awake(int bodyHandle, int flag) { b3BodyId id = b3d_get_body(bodyHandle); if (B3_IS_NON_NULL(id)) { b3Body_SetAwake(id, flag != 0); } }
B3D_EXPORT void b3d_body_enable_sleep(int bodyHandle, int flag) { b3BodyId id = b3d_get_body(bodyHandle); if (B3_IS_NON_NULL(id)) { b3Body_EnableSleep(id, flag != 0); } }
B3D_EXPORT int b3d_body_is_sleep_enabled(int bodyHandle) { b3BodyId id = b3d_get_body(bodyHandle); return B3_IS_NON_NULL(id) && b3Body_IsSleepEnabled(id); }
B3D_EXPORT int b3d_body_is_enabled(int bodyHandle) { b3BodyId id = b3d_get_body(bodyHandle); return B3_IS_NON_NULL(id) && b3Body_IsEnabled(id); }
B3D_EXPORT void b3d_body_disable(int bodyHandle) { b3BodyId id = b3d_get_body(bodyHandle); if (B3_IS_NON_NULL(id)) { b3Body_Disable(id); } }
B3D_EXPORT void b3d_body_enable(int bodyHandle) { b3BodyId id = b3d_get_body(bodyHandle); if (B3_IS_NON_NULL(id)) { b3Body_Enable(id); } }
B3D_EXPORT void b3d_body_set_bullet(int bodyHandle, int flag) { b3BodyId id = b3d_get_body(bodyHandle); if (B3_IS_NON_NULL(id)) { b3Body_SetBullet(id, flag != 0); } }
B3D_EXPORT int b3d_body_is_bullet(int bodyHandle) { b3BodyId id = b3d_get_body(bodyHandle); return B3_IS_NON_NULL(id) && b3Body_IsBullet(id); }
B3D_EXPORT int b3d_body_get_world(int bodyHandle) { b3BodyId id = b3d_get_body(bodyHandle); return B3_IS_NON_NULL(id) ? b3d_store_world(b3Body_GetWorld(id)) : 0; }
B3D_EXPORT int b3d_body_get_shape_count(int bodyHandle) { b3BodyId id = b3d_get_body(bodyHandle); return B3_IS_NON_NULL(id) ? b3Body_GetShapeCount(id) : 0; }
B3D_EXPORT int b3d_body_get_joint_count(int bodyHandle) { b3BodyId id = b3d_get_body(bodyHandle); return B3_IS_NON_NULL(id) ? b3Body_GetJointCount(id) : 0; }
B3D_EXPORT void b3d_body_compute_aabb(int bodyHandle, float* out) { b3BodyId id = b3d_get_body(bodyHandle); b3d_write_aabb(out, B3_IS_NON_NULL(id) ? b3Body_ComputeAABB(id) : (b3AABB){0}); }

B3D_EXPORT int b3d_create_sphere(int bodyHandle, float radius, float density, float friction, float restitution)
{
    return b3d_create_sphere_ex(bodyHandle, 0.0f, 0.0f, 0.0f, radius, density, friction, restitution, 0, 1, -1, 0);
}

B3D_EXPORT int b3d_create_sphere_ex(int bodyHandle, float cx, float cy, float cz, float radius, float density, float friction, float restitution, int isSensor, int categoryBits, int maskBits, int groupIndex)
{
    b3BodyId bodyId = b3d_get_body(bodyHandle);
    if (B3_IS_NULL(bodyId) || radius <= 0.0f) { return 0; }
    b3ShapeDef def = b3d_shape_def(density, friction, restitution, isSensor, categoryBits, maskBits, groupIndex);
    b3Sphere sphere = {b3d_vec3(cx, cy, cz), radius};
    return b3d_store_shape(b3CreateSphereShape(bodyId, &def, &sphere));
}

B3D_EXPORT int b3d_create_capsule(int bodyHandle, float ax, float ay, float az, float bx, float by, float bz, float radius, float density, float friction, float restitution)
{
    b3BodyId bodyId = b3d_get_body(bodyHandle);
    if (B3_IS_NULL(bodyId) || radius <= 0.0f) { return 0; }
    b3ShapeDef def = b3d_shape_def(density, friction, restitution, 0, 1, -1, 0);
    b3Capsule capsule = {b3d_vec3(ax, ay, az), b3d_vec3(bx, by, bz), radius};
    return b3d_store_shape(b3CreateCapsuleShape(bodyId, &def, &capsule));
}

B3D_EXPORT int b3d_create_box(int bodyHandle, float hx, float hy, float hz, float density, float friction, float restitution)
{
    b3BodyId bodyId = b3d_get_body(bodyHandle);
    if (B3_IS_NULL(bodyId) || hx <= 0.0f || hy <= 0.0f || hz <= 0.0f) { return 0; }
    b3ShapeDef def = b3d_shape_def(density, friction, restitution, 0, 1, -1, 0);
    b3BoxHull box = b3MakeBoxHull(hx, hy, hz);
    return b3d_store_shape(b3CreateHullShape(bodyId, &def, &box.base));
}

B3D_EXPORT void b3d_destroy_shape(int shapeHandle)
{
    b3ShapeId id = b3d_get_shape(shapeHandle);
    if (B3_IS_NON_NULL(id)) { b3DestroyShape(id, true); b3d_state.shapes[shapeHandle - 1] = b3_nullShapeId; }
}

B3D_EXPORT int b3d_shape_is_valid(int shapeHandle) { return B3_IS_NON_NULL(b3d_get_shape(shapeHandle)); }
B3D_EXPORT int b3d_shape_get_type(int shapeHandle) { b3ShapeId id = b3d_get_shape(shapeHandle); return B3_IS_NON_NULL(id) ? (int)b3Shape_GetType(id) : -1; }
B3D_EXPORT int b3d_shape_get_body(int shapeHandle) { b3ShapeId id = b3d_get_shape(shapeHandle); return B3_IS_NON_NULL(id) ? b3d_store_body(b3Shape_GetBody(id)) : 0; }
B3D_EXPORT int b3d_shape_is_sensor(int shapeHandle) { b3ShapeId id = b3d_get_shape(shapeHandle); return B3_IS_NON_NULL(id) && b3Shape_IsSensor(id); }
B3D_EXPORT void b3d_shape_set_density(int shapeHandle, float density, int updateMass) { b3ShapeId id = b3d_get_shape(shapeHandle); if (B3_IS_NON_NULL(id)) { b3Shape_SetDensity(id, density, updateMass != 0); } }
B3D_EXPORT float b3d_shape_get_density(int shapeHandle) { b3ShapeId id = b3d_get_shape(shapeHandle); return B3_IS_NON_NULL(id) ? b3Shape_GetDensity(id) : 0.0f; }
B3D_EXPORT void b3d_shape_set_friction(int shapeHandle, float friction) { b3ShapeId id = b3d_get_shape(shapeHandle); if (B3_IS_NON_NULL(id)) { b3Shape_SetFriction(id, friction); } }
B3D_EXPORT float b3d_shape_get_friction(int shapeHandle) { b3ShapeId id = b3d_get_shape(shapeHandle); return B3_IS_NON_NULL(id) ? b3Shape_GetFriction(id) : 0.0f; }
B3D_EXPORT void b3d_shape_set_restitution(int shapeHandle, float restitution) { b3ShapeId id = b3d_get_shape(shapeHandle); if (B3_IS_NON_NULL(id)) { b3Shape_SetRestitution(id, restitution); } }
B3D_EXPORT float b3d_shape_get_restitution(int shapeHandle) { b3ShapeId id = b3d_get_shape(shapeHandle); return B3_IS_NON_NULL(id) ? b3Shape_GetRestitution(id) : 0.0f; }
B3D_EXPORT void b3d_shape_set_filter(int shapeHandle, int categoryBits, int maskBits, int groupIndex, int invokeContacts) { b3ShapeId id = b3d_get_shape(shapeHandle); if (B3_IS_NON_NULL(id)) { b3Filter f = b3DefaultFilter(); f.categoryBits = (uint64_t)(uint32_t)categoryBits; f.maskBits = (uint64_t)(uint32_t)maskBits; f.groupIndex = groupIndex; b3Shape_SetFilter(id, f, invokeContacts != 0); } }
B3D_EXPORT void b3d_shape_enable_sensor_events(int shapeHandle, int flag) { b3ShapeId id = b3d_get_shape(shapeHandle); if (B3_IS_NON_NULL(id)) { b3Shape_EnableSensorEvents(id, flag != 0); } }
B3D_EXPORT void b3d_shape_enable_contact_events(int shapeHandle, int flag) { b3ShapeId id = b3d_get_shape(shapeHandle); if (B3_IS_NON_NULL(id)) { b3Shape_EnableContactEvents(id, flag != 0); } }
B3D_EXPORT void b3d_shape_enable_hit_events(int shapeHandle, int flag) { b3ShapeId id = b3d_get_shape(shapeHandle); if (B3_IS_NON_NULL(id)) { b3Shape_EnableHitEvents(id, flag != 0); } }
B3D_EXPORT void b3d_shape_get_aabb(int shapeHandle, float* out) { b3ShapeId id = b3d_get_shape(shapeHandle); b3d_write_aabb(out, B3_IS_NON_NULL(id) ? b3Shape_GetAABB(id) : (b3AABB){0}); }
B3D_EXPORT void b3d_shape_compute_mass_data(int shapeHandle, float* out) { b3ShapeId id = b3d_get_shape(shapeHandle); b3d_write_mass(out, B3_IS_NON_NULL(id) ? b3Shape_ComputeMassData(id) : (b3MassData){0}); }
B3D_EXPORT void b3d_shape_get_closest_point(int shapeHandle, float x, float y, float z, float* out) { b3ShapeId id = b3d_get_shape(shapeHandle); b3d_write_vec3(out, B3_IS_NON_NULL(id) ? b3Shape_GetClosestPoint(id, b3d_vec3(x, y, z)) : b3d_vec3(0, 0, 0)); }
B3D_EXPORT void b3d_shape_ray_cast(int shapeHandle, float ox, float oy, float oz, float tx, float ty, float tz, float* out) { b3ShapeId id = b3d_get_shape(shapeHandle); b3d_write_cast_output(out, B3_IS_NON_NULL(id) ? b3Shape_RayCast(id, (b3Pos){ox, oy, oz}, b3d_vec3(tx, ty, tz)) : (b3WorldCastOutput){0}); }

static void b3d_fill_joint_base(b3JointDef* base, int bodyA, int bodyB, float ax, float ay, float az, float aqx, float aqy, float aqz, float aqw, float bx, float by, float bz, float bqx, float bqy, float bqz, float bqw, int collideConnected)
{
    base->bodyIdA = b3d_get_body(bodyA);
    base->bodyIdB = b3d_get_body(bodyB);
    base->localFrameA = b3d_transform(ax, ay, az, aqx, aqy, aqz, aqw);
    base->localFrameB = b3d_transform(bx, by, bz, bqx, bqy, bqz, bqw);
    base->collideConnected = collideConnected != 0;
}

B3D_EXPORT int b3d_create_distance_joint(int worldHandle, int bodyA, int bodyB, float ax, float ay, float az, float bx, float by, float bz, float length)
{
    b3WorldId worldId = b3d_get_world(worldHandle);
    if (B3_IS_NULL(worldId)) { return 0; }
    b3DistanceJointDef def = b3DefaultDistanceJointDef();
    b3d_fill_joint_base(&def.base, bodyA, bodyB, ax, ay, az, 0, 0, 0, 1, bx, by, bz, 0, 0, 0, 1, 0);
    if (B3_IS_NULL(def.base.bodyIdA) || B3_IS_NULL(def.base.bodyIdB)) { return 0; }
    def.length = length;
    return b3d_store_joint(b3CreateDistanceJoint(worldId, &def));
}

B3D_EXPORT int b3d_create_filter_joint(int worldHandle, int bodyA, int bodyB)
{
    b3WorldId worldId = b3d_get_world(worldHandle);
    if (B3_IS_NULL(worldId)) { return 0; }
    b3FilterJointDef def = b3DefaultFilterJointDef();
    b3d_fill_joint_base(&def.base, bodyA, bodyB, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0);
    if (B3_IS_NULL(def.base.bodyIdA) || B3_IS_NULL(def.base.bodyIdB)) { return 0; }
    return b3d_store_joint(b3CreateFilterJoint(worldId, &def));
}

B3D_EXPORT int b3d_create_weld_joint(int worldHandle, int bodyA, int bodyB, float ax, float ay, float az, float bx, float by, float bz)
{
    b3WorldId worldId = b3d_get_world(worldHandle);
    if (B3_IS_NULL(worldId)) { return 0; }
    b3WeldJointDef def = b3DefaultWeldJointDef();
    b3d_fill_joint_base(&def.base, bodyA, bodyB, ax, ay, az, 0, 0, 0, 1, bx, by, bz, 0, 0, 0, 1, 0);
    if (B3_IS_NULL(def.base.bodyIdA) || B3_IS_NULL(def.base.bodyIdB)) { return 0; }
    return b3d_store_joint(b3CreateWeldJoint(worldId, &def));
}

B3D_EXPORT void b3d_destroy_joint(int jointHandle, int wakeAttached) { b3JointId id = b3d_get_joint(jointHandle); if (B3_IS_NON_NULL(id)) { b3DestroyJoint(id, wakeAttached != 0); b3d_state.joints[jointHandle - 1] = b3_nullJointId; } }
B3D_EXPORT int b3d_joint_is_valid(int jointHandle) { return B3_IS_NON_NULL(b3d_get_joint(jointHandle)); }
B3D_EXPORT int b3d_joint_get_type(int jointHandle) { b3JointId id = b3d_get_joint(jointHandle); return B3_IS_NON_NULL(id) ? (int)b3Joint_GetType(id) : -1; }
B3D_EXPORT int b3d_joint_get_body_a(int jointHandle) { b3JointId id = b3d_get_joint(jointHandle); return B3_IS_NON_NULL(id) ? b3d_store_body(b3Joint_GetBodyA(id)) : 0; }
B3D_EXPORT int b3d_joint_get_body_b(int jointHandle) { b3JointId id = b3d_get_joint(jointHandle); return B3_IS_NON_NULL(id) ? b3d_store_body(b3Joint_GetBodyB(id)) : 0; }
B3D_EXPORT void b3d_joint_get_constraint_force(int jointHandle, float* out) { b3JointId id = b3d_get_joint(jointHandle); b3d_write_vec3(out, B3_IS_NON_NULL(id) ? b3Joint_GetConstraintForce(id) : b3d_vec3(0, 0, 0)); }
B3D_EXPORT void b3d_joint_get_constraint_torque(int jointHandle, float* out) { b3JointId id = b3d_get_joint(jointHandle); b3d_write_vec3(out, B3_IS_NON_NULL(id) ? b3Joint_GetConstraintTorque(id) : b3d_vec3(0, 0, 0)); }
B3D_EXPORT float b3d_joint_get_linear_separation(int jointHandle) { b3JointId id = b3d_get_joint(jointHandle); return B3_IS_NON_NULL(id) ? b3Joint_GetLinearSeparation(id) : 0.0f; }
B3D_EXPORT float b3d_joint_get_angular_separation(int jointHandle) { b3JointId id = b3d_get_joint(jointHandle); return B3_IS_NON_NULL(id) ? b3Joint_GetAngularSeparation(id) : 0.0f; }
B3D_EXPORT void b3d_distance_joint_set_length(int jointHandle, float length) { b3JointId id = b3d_get_joint(jointHandle); if (B3_IS_NON_NULL(id)) { b3DistanceJoint_SetLength(id, length); } }
B3D_EXPORT float b3d_distance_joint_get_length(int jointHandle) { b3JointId id = b3d_get_joint(jointHandle); return B3_IS_NON_NULL(id) ? b3DistanceJoint_GetLength(id) : 0.0f; }
B3D_EXPORT void b3d_distance_joint_enable_spring(int jointHandle, int flag) { b3JointId id = b3d_get_joint(jointHandle); if (B3_IS_NON_NULL(id)) { b3DistanceJoint_EnableSpring(id, flag != 0); } }
B3D_EXPORT void b3d_distance_joint_set_spring_hertz(int jointHandle, float v) { b3JointId id = b3d_get_joint(jointHandle); if (B3_IS_NON_NULL(id)) { b3DistanceJoint_SetSpringHertz(id, v); } }
B3D_EXPORT void b3d_distance_joint_set_spring_damping_ratio(int jointHandle, float v) { b3JointId id = b3d_get_joint(jointHandle); if (B3_IS_NON_NULL(id)) { b3DistanceJoint_SetSpringDampingRatio(id, v); } }
B3D_EXPORT void b3d_distance_joint_enable_limit(int jointHandle, int flag) { b3JointId id = b3d_get_joint(jointHandle); if (B3_IS_NON_NULL(id)) { b3DistanceJoint_EnableLimit(id, flag != 0); } }
B3D_EXPORT void b3d_distance_joint_set_length_range(int jointHandle, float minLength, float maxLength) { b3JointId id = b3d_get_joint(jointHandle); if (B3_IS_NON_NULL(id)) { b3DistanceJoint_SetLengthRange(id, minLength, maxLength); } }
B3D_EXPORT void b3d_distance_joint_enable_motor(int jointHandle, int flag) { b3JointId id = b3d_get_joint(jointHandle); if (B3_IS_NON_NULL(id)) { b3DistanceJoint_EnableMotor(id, flag != 0); } }
B3D_EXPORT void b3d_distance_joint_set_motor_speed(int jointHandle, float speed) { b3JointId id = b3d_get_joint(jointHandle); if (B3_IS_NON_NULL(id)) { b3DistanceJoint_SetMotorSpeed(id, speed); } }
B3D_EXPORT void b3d_distance_joint_set_max_motor_force(int jointHandle, float force) { b3JointId id = b3d_get_joint(jointHandle); if (B3_IS_NON_NULL(id)) { b3DistanceJoint_SetMaxMotorForce(id, force); } }

B3D_EXPORT void b3d_world_cast_ray_closest(int worldHandle, float ox, float oy, float oz, float tx, float ty, float tz, int categoryBits, int maskBits, float* out, int* outShape)
{
    b3WorldId worldId = b3d_get_world(worldHandle);
    b3RayResult result = {0};
    if (B3_IS_NON_NULL(worldId)) { result = b3World_CastRayClosest(worldId, (b3Pos){ox, oy, oz}, b3d_vec3(tx, ty, tz), b3d_query_filter(categoryBits, maskBits)); }
    b3d_write_ray_result(out, outShape, result);
}

B3D_EXPORT int b3d_world_overlap_aabb(int worldHandle, float lx, float ly, float lz, float ux, float uy, float uz, int categoryBits, int maskBits)
{
    b3WorldId worldId = b3d_get_world(worldHandle);
    b3d_state.queryCount = 0;
    if (B3_IS_NULL(worldId)) { return 0; }
    b3AABB aabb = {b3d_vec3(lx, ly, lz), b3d_vec3(ux, uy, uz)};
    b3World_OverlapAABB(worldId, aabb, b3d_query_filter(categoryBits, maskBits), b3d_overlap_callback, NULL);
    return b3d_state.queryCount;
}

B3D_EXPORT int b3d_world_cast_ray_all(int worldHandle, float ox, float oy, float oz, float tx, float ty, float tz, int categoryBits, int maskBits)
{
    b3WorldId worldId = b3d_get_world(worldHandle);
    b3d_state.queryCount = 0;
    if (B3_IS_NULL(worldId)) { return 0; }
    b3World_CastRay(worldId, (b3Pos){ox, oy, oz}, b3d_vec3(tx, ty, tz), b3d_query_filter(categoryBits, maskBits), b3d_cast_callback, NULL);
    return b3d_state.queryCount;
}

B3D_EXPORT int b3d_query_get_count(void) { return b3d_state.queryCount; }
B3D_EXPORT int b3d_query_get_shape(int index) { return index >= 0 && index < b3d_state.queryCount ? b3d_store_shape(b3d_state.queryShapes[index]) : 0; }
B3D_EXPORT void b3d_query_get_hit(int index, float* out) { if (out == NULL) { return; } memset(out, 0, sizeof(float) * 7); if (index < 0 || index >= b3d_state.queryCount) { return; } out[0] = b3d_state.queryPoints[index].x; out[1] = b3d_state.queryPoints[index].y; out[2] = b3d_state.queryPoints[index].z; out[3] = b3d_state.queryNormals[index].x; out[4] = b3d_state.queryNormals[index].y; out[5] = b3d_state.queryNormals[index].z; out[6] = b3d_state.queryFractions[index]; }

B3D_EXPORT int b3d_events_get_body_move_count(int worldHandle) { b3WorldId id = b3d_get_world(worldHandle); return B3_IS_NON_NULL(id) ? b3World_GetBodyEvents(id).moveCount : 0; }
B3D_EXPORT void b3d_events_get_body_move(int worldHandle, int index, float* out, int* outBody) { b3WorldId id = b3d_get_world(worldHandle); if (outBody != NULL) { outBody[0] = 0; } if (B3_IS_NULL(id)) { return; } b3BodyEvents e = b3World_GetBodyEvents(id); if (index < 0 || index >= e.moveCount) { return; } if (outBody != NULL) { outBody[0] = b3d_store_body(e.moveEvents[index].bodyId); } b3d_write_transform(out, e.moveEvents[index].transform); if (out != NULL) { out[7] = e.moveEvents[index].fellAsleep ? 1.0f : 0.0f; } }
B3D_EXPORT int b3d_events_get_sensor_begin_count(int worldHandle) { b3WorldId id = b3d_get_world(worldHandle); return B3_IS_NON_NULL(id) ? b3World_GetSensorEvents(id).beginCount : 0; }
B3D_EXPORT int b3d_events_get_sensor_end_count(int worldHandle) { b3WorldId id = b3d_get_world(worldHandle); return B3_IS_NON_NULL(id) ? b3World_GetSensorEvents(id).endCount : 0; }
B3D_EXPORT void b3d_events_get_sensor_begin(int worldHandle, int index, int* out) { if (out == NULL) { return; } out[0] = out[1] = 0; b3WorldId id = b3d_get_world(worldHandle); if (B3_IS_NULL(id)) { return; } b3SensorEvents e = b3World_GetSensorEvents(id); if (index >= 0 && index < e.beginCount) { out[0] = b3d_store_shape(e.beginEvents[index].sensorShapeId); out[1] = b3d_store_shape(e.beginEvents[index].visitorShapeId); } }
B3D_EXPORT void b3d_events_get_sensor_end(int worldHandle, int index, int* out) { if (out == NULL) { return; } out[0] = out[1] = 0; b3WorldId id = b3d_get_world(worldHandle); if (B3_IS_NULL(id)) { return; } b3SensorEvents e = b3World_GetSensorEvents(id); if (index >= 0 && index < e.endCount) { out[0] = b3d_store_shape(e.endEvents[index].sensorShapeId); out[1] = b3d_store_shape(e.endEvents[index].visitorShapeId); } }
B3D_EXPORT int b3d_events_get_contact_begin_count(int worldHandle) { b3WorldId id = b3d_get_world(worldHandle); return B3_IS_NON_NULL(id) ? b3World_GetContactEvents(id).beginCount : 0; }
B3D_EXPORT int b3d_events_get_contact_end_count(int worldHandle) { b3WorldId id = b3d_get_world(worldHandle); return B3_IS_NON_NULL(id) ? b3World_GetContactEvents(id).endCount : 0; }
B3D_EXPORT int b3d_events_get_contact_hit_count(int worldHandle) { b3WorldId id = b3d_get_world(worldHandle); return B3_IS_NON_NULL(id) ? b3World_GetContactEvents(id).hitCount : 0; }
B3D_EXPORT void b3d_events_get_contact_begin(int worldHandle, int index, int* out) { if (out == NULL) { return; } out[0] = out[1] = 0; b3WorldId id = b3d_get_world(worldHandle); if (B3_IS_NULL(id)) { return; } b3ContactEvents e = b3World_GetContactEvents(id); if (index >= 0 && index < e.beginCount) { out[0] = b3d_store_shape(e.beginEvents[index].shapeIdA); out[1] = b3d_store_shape(e.beginEvents[index].shapeIdB); } }
B3D_EXPORT void b3d_events_get_contact_end(int worldHandle, int index, int* out) { if (out == NULL) { return; } out[0] = out[1] = 0; b3WorldId id = b3d_get_world(worldHandle); if (B3_IS_NULL(id)) { return; } b3ContactEvents e = b3World_GetContactEvents(id); if (index >= 0 && index < e.endCount) { out[0] = b3d_store_shape(e.endEvents[index].shapeIdA); out[1] = b3d_store_shape(e.endEvents[index].shapeIdB); } }
B3D_EXPORT void b3d_events_get_contact_hit(int worldHandle, int index, float* out, int* outShapes) { b3WorldId id = b3d_get_world(worldHandle); if (outShapes != NULL) { outShapes[0] = outShapes[1] = 0; } if (out != NULL) { memset(out, 0, sizeof(float) * 8); } if (B3_IS_NULL(id)) { return; } b3ContactEvents e = b3World_GetContactEvents(id); if (index < 0 || index >= e.hitCount) { return; } b3ContactHitEvent h = e.hitEvents[index]; if (outShapes != NULL) { outShapes[0] = b3d_store_shape(h.shapeIdA); outShapes[1] = b3d_store_shape(h.shapeIdB); } if (out != NULL) { out[0] = h.point.x; out[1] = h.point.y; out[2] = h.point.z; out[3] = h.normal.x; out[4] = h.normal.y; out[5] = h.normal.z; out[6] = h.approachSpeed; } }
B3D_EXPORT int b3d_events_get_joint_count(int worldHandle) { b3WorldId id = b3d_get_world(worldHandle); return B3_IS_NON_NULL(id) ? b3World_GetJointEvents(id).count : 0; }
B3D_EXPORT int b3d_events_get_joint(int worldHandle, int index) { b3WorldId id = b3d_get_world(worldHandle); if (B3_IS_NULL(id)) { return 0; } b3JointEvents e = b3World_GetJointEvents(id); return index >= 0 && index < e.count ? b3d_store_joint(e.jointEvents[index].jointId) : 0; }

B3D_EXPORT void b3d_compute_sphere_mass(float cx, float cy, float cz, float radius, float density, float* out) { b3Sphere s = {b3d_vec3(cx, cy, cz), radius}; b3d_write_mass(out, b3ComputeSphereMass(&s, density)); }
B3D_EXPORT void b3d_compute_capsule_mass(float ax, float ay, float az, float bx, float by, float bz, float radius, float density, float* out) { b3Capsule c = {b3d_vec3(ax, ay, az), b3d_vec3(bx, by, bz), radius}; b3d_write_mass(out, b3ComputeCapsuleMass(&c, density)); }
B3D_EXPORT void b3d_compute_sphere_aabb(float cx, float cy, float cz, float radius, float px, float py, float pz, float qx, float qy, float qz, float qw, float* out) { b3Sphere s = {b3d_vec3(cx, cy, cz), radius}; b3d_write_aabb(out, b3ComputeSphereAABB(&s, b3d_transform(px, py, pz, qx, qy, qz, qw))); }
B3D_EXPORT int b3d_is_valid_ray(float ox, float oy, float oz, float tx, float ty, float tz, float maxFraction) { b3RayCastInput input = {b3d_vec3(ox, oy, oz), b3d_vec3(tx, ty, tz), maxFraction}; return b3IsValidRay(&input); }
B3D_EXPORT void b3d_ray_cast_sphere(float cx, float cy, float cz, float radius, float ox, float oy, float oz, float tx, float ty, float tz, float maxFraction, float* out) { b3Sphere s = {b3d_vec3(cx, cy, cz), radius}; b3RayCastInput input = {b3d_vec3(ox, oy, oz), b3d_vec3(tx, ty, tz), maxFraction}; b3d_write_cast_output(out, b3RayCastSphere(&s, &input)); }
B3D_EXPORT void b3d_ray_cast_capsule(float ax, float ay, float az, float bx, float by, float bz, float radius, float ox, float oy, float oz, float tx, float ty, float tz, float maxFraction, float* out) { b3Capsule c = {b3d_vec3(ax, ay, az), b3d_vec3(bx, by, bz), radius}; b3RayCastInput input = {b3d_vec3(ox, oy, oz), b3d_vec3(tx, ty, tz), maxFraction}; b3d_write_cast_output(out, b3RayCastCapsule(&c, &input)); }
