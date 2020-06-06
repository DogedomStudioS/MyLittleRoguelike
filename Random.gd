extends Reference

const RAND_MAX = 2147483648.0

var current_seed = -1
var current_state = current_seed


func rand_int():
  var r = rand_seed(current_state)
  current_state = r[1]
  return abs(r[0])


func rand_float():
  return rand_int() / RAND_MAX


func rand_range_int(lower, upper):
  if upper <= lower:
    return lower
  
  var range_value = int(upper - lower)
  return lower + (rand_int() % range_value)


func rand_range_float(lower, upper):
  if upper <= lower:
    return lower
  
  var range_value = upper - lower
  return lower + rand_float() * range_value


func rand_roll_int(lower, upper, clump):
  return int(rand_roll_float(lower, upper, clump))


func rand_roll_float(lower, upper, clump):
  if upper <= lower:
    return lower
  
  clump = int(max(clump, 1))
  
  var range_value = upper - lower
  
  var total = 0
  for i in clump:
    total += rand_float() * range_value * (1.0 / clump)
  
  return lower + total


func rand_bool(percentage):
  return rand_int() < RAND_MAX * clamp(percentage, 0, 1)


func rand_array(array):
  # arrays must be [weight, value]
  
  var sum_of_weights = 0
  for t in array:
    sum_of_weights += t[0]
  
  var x = rand_float() * sum_of_weights
  
  var cumulative_weight = 0
  for t in array:
    cumulative_weight += t[0]
    
    if x < cumulative_weight:
      return t[1]


func set_seed(input):
  var new_seed = -1
  
  match typeof(input):
    TYPE_STRING:
      if input.is_valid_float():
        new_seed = input.to_float()
        continue
      
      var b = var2bytes(input)
      
      var total = 0
      for i in b.size():
        total += (1 << i) * b[i]
      
      new_seed = -total
    
    TYPE_INT, TYPE_REAL:
      new_seed = input
  
  current_seed = new_seed
  current_state = current_seed


func randomize_seed():
  set_seed(OS.get_ticks_msec() * 4398046511104 + 4398046511104)
