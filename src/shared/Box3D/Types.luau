--!strict

export type World = { handle: number }
export type Body = { handle: number }
export type Shape = { handle: number }
export type BodyType = "Static" | "Kinematic" | "Dynamic"
export type BodyTypeValues = {
	Static: BodyType,
	Kinematic: BodyType,
	Dynamic: BodyType,
}

export type Quaternion = {
	x: number,
	y: number,
	z: number,
	w: number,
}

export type BodyOptions = {
	bodyType: BodyType?,
	position: Vector3?,
	cframe: CFrame?,
	quaternion: Quaternion?,
}

export type ShapeOptions = {
	density: number?,
	friction: number?,
	restitution: number?,
}

return {
	BodyType = {
		Static = "Static" :: BodyType,
		Kinematic = "Kinematic" :: BodyType,
		Dynamic = "Dynamic" :: BodyType,
	} :: BodyTypeValues,

	BodyTypeIds = {
		Static = 0,
		Kinematic = 1,
		Dynamic = 2,
	} :: { [BodyType]: number },
}
