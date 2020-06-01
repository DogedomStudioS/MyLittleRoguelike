extends Node

var bounds: Rect2 = Rect2(0, 0, 0, 0)
var parent: Node
var children: Array = []

func split(iterations = 1, minimum_size = Vector2(1, 1), variance = 3.0):
    # if iterations < 0 or both width and height are smaller than minimumDimensions, early out.
    var tooSmall = bounds.position.x < 1 or bounds.position.y < 1 or bounds.size.x / 2 < minimum_size.x or bounds.size.y / 2 < minimum_size.y
    if tooSmall: return

    # choose a splitting direction at random,
    # unless the bounds is smaller in one direction
    # than the minimum. In that case, choose the
    # other direction.
    var split_direction
    if bounds.size.x <= minimum_size.x:
        split_direction = 'x'
    elif bounds.size.y <= minimum_size.y:
        split_direction = 'y'
    
    # After choosing a direction, choose a position.
    # split from -variance < half < variance, where
    # variance is a tunable value.
    var minimum_split = floor(bounds.size[split_direction] / 2.0) - floor(bounds.size[split_direction] * variance)
    var split_position = randi() % int(variance * 2) + int(minimum_split)
    
    # Create two new leaves and add them to children.
    # Set parent as self.
    # The first has a bounds of x to the split, the second has a bounds of the split + 1 to x + width.
    # Height is handled oppositely (y to split -1, split to y + height).
    

    # Call new leaf nodes' split(iterations -1)
