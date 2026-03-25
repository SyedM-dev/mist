def intersects?(rect1, rect2)
  x1, y1, w1, h1 = rect1
  x2, y2, w2, h2 = rect2

  # No overlap conditions
  return false if x1 + w1 <= x2   # rect1 is left of rect2
  return false if x1 >= x2 + w2   # rect1 is right of rect2
  return false if y1 + h1 <= y2   # rect1 is above rect2
  return false if y1 >= y2 + h2   # rect1 is below rect2

  true  # overlap exists
end