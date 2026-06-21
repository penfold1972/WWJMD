extends Node

## WWJMD Global Singletons
## Stage 1: Lead Game Architect

const VERSION: String = "0.1.0"
const FRAGMENT_LIFETIME: float = 5.0

enum DestructionPhase {
	INDESTRUCTIBLE,   # Phase 1
	DENT,             # Phase 2
	DAMAGED,          # Phase 3
	DESTROYED         # Phase 4
}
