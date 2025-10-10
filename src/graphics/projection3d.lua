-- src/graphics/projection3d.lua
-- Comprehensive 3D projection system for LOVE2D
-- Supports isometric, perspective, and orthographic projections with camera controls

local Projection3D = {}

-- ===== VECTOR MATH =====
local Vec3 = {}
Vec3.__index = Vec3

function Vec3.new(x, y, z)
    return setmetatable({x = x or 0, y = y or 0, z = z or 0}, Vec3)
end

function Vec3:add(other)
    return Vec3.new(self.x + other.x, self.y + other.y, self.z + other.z)
end

function Vec3:sub(other)
    return Vec3.new(self.x - other.x, self.y - other.y, self.z - other.z)
end

function Vec3:mul(scalar)
    return Vec3.new(self.x * scalar, self.y * scalar, self.z * scalar)
end

function Vec3:dot(other)
    return self.x * other.x + self.y * other.y + self.z * other.z
end

function Vec3:cross(other)
    return Vec3.new(
        self.y * other.z - self.z * other.y,
        self.z * other.x - self.x * other.z,
        self.x * other.y - self.y * other.x
    )
end

function Vec3:length()
    return math.sqrt(self.x * self.x + self.y * self.y + self.z * self.z)
end

function Vec3:normalize()
    local len = self:length()
    if len > 0 then
        return self:mul(1 / len)
    end
    return Vec3.new(0, 0, 0)
end

-- ===== MATRIX MATH =====
local Matrix4 = {}
Matrix4.__index = Matrix4

function Matrix4.new(...)
    local args = {...}
    local m = {}
    for i = 1, 16 do
        m[i] = args[i] or 0
    end
    return setmetatable(m, Matrix4)
end

function Matrix4.identity()
    return Matrix4.new(
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1
    )
end

function Matrix4:mul(other)
    local result = Matrix4.new()
    for row = 0, 3 do
        for col = 0, 3 do
            local sum = 0
            for k = 0, 3 do
                sum = sum + self[row * 4 + k + 1] * other[k * 4 + col + 1]
            end
            result[row * 4 + col + 1] = sum
        end
    end
    return result
end

function Matrix4:transform(vec3)
    local x, y, z = vec3.x, vec3.y, vec3.z
    local w = self[4] * x + self[8] * y + self[12] * z + self[16]
    if w == 0 then w = 1 end
    
    return Vec3.new(
        (self[1] * x + self[5] * y + self[9] * z + self[13]) / w,
        (self[2] * x + self[6] * y + self[10] * z + self[14]) / w,
        (self[3] * x + self[7] * y + self[11] * z + self[15]) / w
    ), w
end

-- ===== TRANSFORMATION MATRICES =====
function Matrix4.translation(x, y, z)
    return Matrix4.new(
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        x, y, z, 1
    )
end

function Matrix4.rotationX(angle)
    local c, s = math.cos(angle), math.sin(angle)
    return Matrix4.new(
        1, 0, 0, 0,
        0, c, s, 0,
        0, -s, c, 0,
        0, 0, 0, 1
    )
end

function Matrix4.rotationY(angle)
    local c, s = math.cos(angle), math.sin(angle)
    return Matrix4.new(
        c, 0, -s, 0,
        0, 1, 0, 0,
        s, 0, c, 0,
        0, 0, 0, 1
    )
end

function Matrix4.rotationZ(angle)
    local c, s = math.cos(angle), math.sin(angle)
    return Matrix4.new(
        c, s, 0, 0,
        -s, c, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1
    )
end

function Matrix4.scale(sx, sy, sz)
    sz = sz or sy or sx
    return Matrix4.new(
        sx, 0, 0, 0,
        0, sy, 0, 0,
        0, 0, sz, 0,
        0, 0, 0, 1
    )
end

-- ===== PROJECTION MATRICES =====
function Matrix4.perspective(fov, aspect, near, far)
    local f = 1 / math.tan(fov / 2)
    local nf = 1 / (near - far)
    
    return Matrix4.new(
        f / aspect, 0, 0, 0,
        0, f, 0, 0,
        0, 0, (far + near) * nf, -1,
        0, 0, 2 * far * near * nf, 0
    )
end

function Matrix4.orthographic(left, right, bottom, top, near, far)
    local rl = 1 / (right - left)
    local tb = 1 / (top - bottom)
    local fn = 1 / (far - near)
    
    return Matrix4.new(
        2 * rl, 0, 0, 0,
        0, 2 * tb, 0, 0,
        0, 0, -2 * fn, 0,
        -(right + left) * rl, -(top + bottom) * tb, -(far + near) * fn, 1
    )
end

-- ===== CAMERA SYSTEM =====
-- Sostituisci la dichiarazione delle camere:
local cameras = {
    perspective = Camera3D.new({projection = "perspective", z = 8}),
    isometric = Camera3D.new({projection = "isometric", x = 5, y = 5, z = 5, size = 40}),
    orthographic = Camera3D.new({projection = "orthographic", z = 5, size = 40})
}

function Camera3D.new(opts)
    opts = opts or {}
    local cam = {
        position = Vec3.new(opts.x or 0, opts.y or 0, opts.z or 5),
        target = Vec3.new(opts.targetX or 0, opts.targetY or 0, opts.targetZ or 0),
        up = Vec3.new(0, 1, 0),
        
        -- Projection settings
        projection = opts.projection or "perspective", -- "perspective", "orthographic", "isometric"
        fov = opts.fov or math.rad(60),
        aspect = opts.aspect or (love.graphics.getWidth() / love.graphics.getHeight()),
        near = opts.near or 0.1,
        far = opts.far or 1000,
        
        -- Screen mapping
        screenWidth = love.graphics.getWidth(),
        screenHeight = love.graphics.getHeight(),
        scale = opts.scale or 100,
        
        -- Cached matrices
        viewMatrix = Matrix4.identity(),
        projMatrix = Matrix4.identity(),
        viewProjMatrix = Matrix4.identity(),
        dirty = true
    }
    
    return setmetatable(cam, Camera3D)
end

function Camera3D:setPosition(x, y, z)
    self.position = Vec3.new(x, y, z)
    self.dirty = true
end

function Camera3D:setTarget(x, y, z)
    self.target = Vec3.new(x, y, z)
    self.dirty = true
end

function Camera3D:setProjection(projType)
    self.projection = projType
    self.dirty = true
end

function Camera3D:updateMatrices()
    if not self.dirty then return end
    
    -- View matrix (look-at)
    local forward = self.target:sub(self.position):normalize()
    local right = forward:cross(self.up):normalize()
    local up = right:cross(forward):normalize()
    
    self.viewMatrix = Matrix4.new(
        right.x, up.x, -forward.x, 0,
        right.y, up.y, -forward.y, 0,
        right.z, up.z, -forward.z, 0,
        -right:dot(self.position), -up:dot(self.position), forward:dot(self.position), 1
    )
    
    -- Projection matrix
        elseif self.projection == "orthographic" then
    local size = self.size or 40
    self.projMatrix = Matrix4.orthographic(-size, size, -size, size, self.near, self.far)
elseif self.projection == "isometric" then
    -- Isometric is orthographic with specific camera angle
    local size = self.size or 40
    self.projMatrix = Matrix4.orthographic(-size, size, -size, size, self.near, self.far)
    -- Apply isometric rotation
    local isoRot = Matrix4.rotationX(math.rad(35.264)):mul(Matrix4.rotationY(math.rad(45)))
    self.viewMatrix = isoRot:mul(self.viewMatrix)
    end
    
    self.viewProjMatrix = self.projMatrix:mul(self.viewMatrix)
    self.dirty = false
    end
end

function Camera3D:project(point3d)
    self:updateMatrices()
    
    local projected, w = self.viewProjMatrix:transform(point3d)
    
    -- Convert to screen coordinates
    local screenX = (projected.x + 1) * 0.5 * self.screenWidth
    local screenY = (1 - projected.y) * 0.5 * self.screenHeight
    
    return screenX, screenY, projected.z, w
end

function Camera3D:worldToScreen(x, y, z)
    return self:project(Vec3.new(x, y, z))
end

-- ===== MAIN PROJECTION3D API =====
Projection3D.Vec3 = Vec3
Projection3D.Matrix4 = Matrix4
Projection3D.Camera3D = Camera3D

-- Default camera instances
local cameras = {
    perspective = Camera3D.new({projection = "perspective", z = 8}),
    isometric = Camera3D.new({projection = "isometric", x = 5, y = 5, z = 5}),
    orthographic = Camera3D.new({projection = "orthographic", z = 5})
}

local currentCamera = cameras.perspective

function Projection3D.setCamera(cameraType)
    if cameras[cameraType] then
        currentCamera = cameras[cameraType]
        currentCamera.screenWidth = love.graphics.getWidth()
        currentCamera.screenHeight = love.graphics.getHeight()
        currentCamera.aspect = currentCamera.screenWidth / currentCamera.screenHeight
        currentCamera.dirty = true
    end
end

function Projection3D.getCamera(cameraType)
    return cameraType and cameras[cameraType] or currentCamera
end

function Projection3D.project(x, y, z, cameraType)
    local cam = cameraType and cameras[cameraType] or currentCamera
    return cam:worldToScreen(x, y, z)
end

-- Convenience functions for different projections
function Projection3D.projectPerspective(x, y, z)
    return cameras.perspective:worldToScreen(x, y, z)
end

function Projection3D.projectIsometric(x, y, z)
    return cameras.isometric:worldToScreen(x, y, z)
end

function Projection3D.projectOrthographic(x, y, z)
    return cameras.orthographic:worldToScreen(x, y, z)
end

-- Update screen dimensions
function Projection3D.resize(width, height)
    for _, cam in pairs(cameras) do
        cam.screenWidth = width
        cam.screenHeight = height
        cam.aspect = width / height
        cam.dirty = true
    end
end

return Projection3D