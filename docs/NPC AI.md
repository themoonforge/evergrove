# NPC AI

## Requirements

- time based behavior like wake up in the morning and go to bed in the evening
- target based movement including path finding
- ability to take a task (provided by the player) from a queue of things to do
- maybe some kind of basic dwarf like needs like eat, sleep, drink beer
  - sleep for active time to force back into bed instead of fixed timer
  - eat once a day or so, maybe combine with an energy meter and let task cost more or less energy
  - drink beer for some general happiness factor, more of a low background constraint

## Components

- global AI controller, which handles everything beyond and individual agent
  - could contain the global task queue
  - use for delegating tasks to unoccupied agents in regards to distance
- Agent controller which is attached to an individual NPC
- tasks which can be moved between global and npc queues
  - probably a task should have attributes like a location and energy cost
- queues as containers for tasks
  - global queue for player created tasks in the game which aren't assigned/worked on
  - individual queue per agent for his own assignments and needs like "I need to sleep" which aren't related to a global game state
- AI related game object e.g. bed, food, beer
  - similar to agent controller but more static for AI interaction for non-tasks
  - registered at global hivemind controller so agents can "query it"
  - probably fixed type and "in use" state

## Event Flows

- spawn agent
  - create controller and attach to NPC
  - register individual agent at global hivemind controller

- player creates task
  - create task object
  - assign task attributes like location, energy cost etc
  - add task to global hivemind queue

- agent needs
  - process agent attributes/needs "on tick"
  - if a soft trigger level is reached like "energy low" create a task at agent queue level
  - if a hard trigger is reached e.g. "energy empty" hand back all global tasks and only do high importance agent need task

- query global AI game object
  - ask global controller for e.g. a bed location to use
  - global controller keeps track of (un)used beds and answers/assigns on to individual agent as target
  - agent moves to object and uses ist
  - global controller gets update from agent if bed is free again or food was eaten/despawned

- how to handle deadlocks?
  - create some kind of error trigger if a task can't be completed
  - maybe check if agent hasn't moved (closer) to task location in X timeframe?
  - maybe check if agent tried and failed multiple times to do the same task?