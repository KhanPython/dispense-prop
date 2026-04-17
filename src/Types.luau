--!strict

export type PropInstance = Model | BasePart
export type TargetInstance = Model | BasePart
export type DynamicNumber = number | Vector2 | (number) -> number
export type PropSettings = {
	RemoveMagnitude: number?,
	AttractMagnitude: number?,
	AttractDuration: DynamicNumber?,
	AttractDelay: DynamicNumber?,
	AutoRemoveTime: number?,
	CollisionGroup: string?,
	OnSpawn: (PropInstance) -> (),
	OnRemoved: ((boolean?) -> ())?,
	OnAllRemoved: (() -> ())?,
}

return nil
