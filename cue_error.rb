class CueError < StandardError; end
class CueError404 < CueError; end
class CueErrorIndex < CueError; end
class CueErrorDuration < CueError; end
class CueErrorRange < CueError; end
class CueTimeError < CueError; end
class CueTimeMaxValue < CueTimeError; end
class CueTimeInvalidFormat < CueTimeError; end
class CueTimeNegative < CueTimeError; end
