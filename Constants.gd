extends Reference


enum DICE {
  d4 = 4,
  d6 = 6,
  d8 = 8,
  d10 = 10,
  d12 = 12,
  d20 = 20
 }

var directions = {
  "up": Vector2.UP,
  "right": Vector2.RIGHT,
  "down": Vector2.DOWN,
  "left": Vector2.LEFT
}

func roll_dice(die, count: int):
  var result = 0
  var minimum = count
  var maximum = count * DICE[die]
  for _i in range(count):
    result += Random.rand_roll_int(minimum, maximum, 1.5)
  return result
