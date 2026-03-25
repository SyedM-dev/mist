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

def line_of_sight?(x1, y1, x2, y2, rect)
  rx, ry, rw, rh = rect
  rx, ry, rw, rh = rx - 2, ry - 2, rw + 4, rh + 4

  # The 4 edges of the rect as line segments
  edges = [
    [rx,      ry,      rx + rw, ry     ],  # top
    [rx,      ry + rh, rx + rw, ry + rh],  # bottom
    [rx,      ry,      rx,      ry + rh],  # left
    [rx + rw, ry,      rx + rw, ry + rh],  # right
  ]

  !(edges.any? { |ex1, ey1, ex2, ey2| segments_intersect?(x1, y1, x2, y2, ex1, ey1, ex2, ey2) })
end

def segments_intersect?(ax1, ay1, ax2, ay2, bx1, by1, bx2, by2)
  dx1 = ax2 - ax1
  dy1 = ay2 - ay1
  dx2 = bx2 - bx1
  dy2 = by2 - by1

  denom = dx1 * dy2 - dy1 * dx2
  return false if denom == 0  # parallel

  t = ((bx1 - ax1) * dy2 - (by1 - ay1) * dx2).to_f / denom
  u = ((bx1 - ax1) * dy1 - (by1 - ay1) * dx1).to_f / denom

  t.between?(0, 1) && u.between?(0, 1)
end