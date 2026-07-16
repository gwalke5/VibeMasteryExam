### Vibe Mastery Exam: Dolch Sight-Word Game App ###

This is a completely different assignment from Solo 3 and the project, featuring different code and performing a separate
function.

### Scoring System ###

The score is calculated using the equation, (total_matches) + ceil(((total_matches)^2) * (time_remaining/15))

The fifteen is half the total time alloted per round.
This scoring system rewards fast completions.  

I chose This equation over simply incrementing total_matches because I wanted players to be rewarded for completing
quickly. The cost of this approach is incentivizing rushed play to get the highest score possible. This will hold up until
the player atrophies and begins to slowly worsen over an extended length of play. 

### Game Chosen ###

I chose the word matching game over the flash card game because it would be much easier to implement with AI, and,
from what I thought, would prevent major errors when generating code. The cost of this approach is the reward for
simple pattern recognition and does not test understanding of words. This will hold up until the player has played
so many times that the tool becomes less capable.
