include("shared.lua")
surface.CreateFont("HUDNumber5", {
	size = 44,
	weight = 800,
	antialias = true,
	shadow = false,
	font = "Trebuchet"})

local matBallGlow = Material("models/props_combine/tpballglow")
function ENT:Draw()
	self.height = self.height or 0
	self.colr = self.colr or 1
	self.colg = self.colg or 0
	self.StartTime = self.StartTime or CurTime()

	if GAMEMODE.Config.shipmentspawntime > 0 and self.height < self:OBBMaxs().z then
		self:drawSpawning()
	else
		self:DrawModel()
	end

	self:drawFloatingGun()
	self:drawInfo()
end

function ENT:drawSpawning()
	render.MaterialOverride(matBallGlow)

	render.SetColorModulation(self.colr, self.colg, 0)

	self:DrawModel()

	render.MaterialOverride()
	self.colr = 1 - ((CurTime() - self.StartTime) / GAMEMODE.Config.shipmentspawntime)
	self.colg = (CurTime() - self.StartTime) / GAMEMODE.Config.shipmentspawntime

	render.SetColorModulation(1, 1, 1)

	render.MaterialOverride()

	local normal = - self:GetAngles():Up()
	local pos = self:LocalToWorld(Vector(0, 0, self:OBBMins().z + self.height))
	local distance = normal:Dot(pos)
	self.height = self:OBBMaxs().z * ((CurTime() - self.StartTime) / GAMEMODE.Config.shipmentspawntime)
	render.EnableClipping(true)
	render.PushCustomClipPlane(normal, distance);

	self:DrawModel()

	render.PopCustomClipPlane()
end

function ENT:drawFloatingGun()
	local contents = CustomShipments[self.dt.contents or ""]
	if not contents or not IsValid(self.dt.gunModel) then return end
	self.dt.gunModel:SetNoDraw(true)

	local pos = self:GetPos()
	local ang = self:GetAngles()

	-- Position the gun
	local gunPos = self:GetAngles():Up() * 40 + ang:Up() * (math.sin(CurTime() * 3) * 8)
	self.dt.gunModel:SetPos(pos + gunPos)


	-- Make it dance
	ang:RotateAroundAxis(ang:Up(), (CurTime() * 180) % 360)
	self.dt.gunModel:SetAngles(ang)

	-- Draw the model
	if self.dt.gunspawn < CurTime() - 2 then
		self.dt.gunModel:DrawModel()
		return
	elseif self.dt.gunspawn < CurTime() then -- Not when a gun just spawned
		return
	end

	-- Draw the spawning effect
	local delta = self.dt.gunspawn - CurTime()
	local min, max = self.dt.gunModel:OBBMins(), self.dt.gunModel:OBBMaxs()
	min, max = self.dt.gunModel:LocalToWorld(min), self.dt.gunModel:LocalToWorld(max)

	-- Draw the ghosted weapon
	render.MaterialOverride(matBallGlow)
	render.SetColorModulation(1 - delta, delta, 0) -- From red to green
	self.dt.gunModel:DrawModel()
	render.MaterialOverride()
	render.SetColorModulation(1, 1, 1)

	-- Draw the cut-off weapon
	render.EnableClipping(true)
	-- The clipping plane only draws objects that face the plane
	local normal = -self.dt.gunModel:GetAngles():Forward()
	local cutPosition = LerpVector(delta, max, min) -- Where it cuts
	local cutDistance = normal:Dot(cutPosition)-- Project the vector onto the normal to get the shortest distance between the plane and origin

	-- Activate the plane
	render.PushCustomClipPlane(normal, cutDistance);
	-- Draw the partial model
	self.dt.gunModel:DrawModel()
	-- Remove the plane
	render.PopCustomClipPlane()

	render.EnableClipping(false)
end

function ENT:drawInfo()
	local Pos = self:GetPos()
	local Ang = self:GetAngles()

	local content = self.dt.contents or ""
	local contents = CustomShipments[content]
	if not contents then return end
	contents = contents.name

	surface.SetFont("HUDNumber5")
	local TextWidth = surface.GetTextSize("Contents:")
	local TextWidth2 = surface.GetTextSize(contents)

	cam.Start3D2D(Pos + Ang:Up() * 25, Ang, 0.2)
		draw.WordBox(2, -TextWidth*0.5 + 5, -30, "Contents:", "HUDNumber5", Color(140, 0, 0, 100), Color(255,255,255,255))
		draw.WordBox(2, -TextWidth2*0.5 + 5, 18, contents, "HUDNumber5", Color(140, 0, 0, 100), Color(255,255,255,255))
	cam.End3D2D()

	Ang:RotateAroundAxis(Ang:Forward(), 90)

	TextWidth = surface.GetTextSize("Amount left:")
	TextWidth2 = surface.GetTextSize(self.dt.count)

	cam.Start3D2D(Pos + Ang:Up() * 17, Ang, 0.14)
		draw.WordBox(2, -TextWidth*0.5 + 5, -150, "Amount left:", "HUDNumber5", Color(140, 0, 0, 100), Color(255,255,255,255))
		draw.WordBox(2, -TextWidth2*0.5 + 0, -102, self.dt.count, "HUDNumber5", Color(140, 0, 0, 100), Color(255,255,255,255))
	cam.End3D2D()
end