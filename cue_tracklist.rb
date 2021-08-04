class CueTracklist
  attr_reader :duration, :tracks

  def initialize(duration = nil)
    @tracks = []
    @duration = duration ? CueTime.new(duration) : duration
  end

  def get_all
    @tracks
  end

  def load_tracks(tracks)
    raise 'The track can only be CueTrack' if tracks.any? { |track| !track.is_a? CueTrack}
    @tracks = tracks
  end

  def duration=(time_str)
    duration = CueTime.new(time_str)

    if @tracks.size.nonzero? && duration <= @tracks.last.index
      raise "Total duration must be > start index last track!" +
              "\nIndex last track = #{@tracks.last.index}"
    end
    @duration = duration
  end

  # REFACTOR
  def add_chapter(number:, duration:, title:, performer: nil, composer: nil)
    duration_new_chapter = CueTime.new(duration)
    new_index = CueTime.new
    number = number.abs

    # If the chapter is added to the end after the existing tracks
    if number > @tracks.size && @tracks.size.nonzero?
      raise_duration_cue(number)
      new_index = (new_index + @duration) - duration_new_chapter
      number = @tracks.size + 1
      raise_duration_chapter(new_index, @tracks.last.index)

      # If a chapter is added to an empty CUE, those will be the first chapter
    elsif @tracks.size.zero?
      @duration = duration_new_chapter
      number = 1

      # If a chapter is added to the beginning of a CUE, that already contains chapters
    elsif @tracks.size.nonzero? && number == 1
      tracks_next = @tracks[number - 1]
      tracks_next_index = tracks_next.index.dup + duration_new_chapter
      raise_duration_chapter(@tracks[1].index, tracks_next_index)
      tracks_next.index = tracks_next_index

      # If a chapter is added between chapters
      # if index < @tracks.size && @tracks.size > 0
    else
      tracks_next = @tracks[number - 1]
      new_index = (new_index + tracks_next.index) - duration_new_chapter
      raise_duration_chapter(new_index, @tracks[number - 2].index)
    end

    renumber_tracks(number) if number <= @tracks.size
    track_new = CueTrack.new(number: number,
                             title: title,
                             performer: performer,
                             composer: composer,
                             index: new_index)
    @tracks.insert(number - 1, track_new)
  end


  def insert_chapter(number:, duration:, title:, performer: nil, composer: nil)
    duration_new_chapter = CueTime.new(duration)
    new_index = CueTime.new
    number = number.abs

    # If the chapter is added to the end after the existing tracks
    if number > @tracks.size && @tracks.size.nonzero?
      raise_duration_cue(number)
      new_index = CueTime.new + @duration
      @duration + duration_new_chapter
      number = @tracks.size + 1

      # If a chapter is added to an empty CUE, those will be the first chapter
    elsif @tracks.size.zero?
      @duration = duration_new_chapter
      number = 1

      # If a chapter is added to the beginning of a CUE, that already contains chapters
    elsif @tracks.size.nonzero? && number == 1
      @duration = @duration + duration_new_chapter unless @duration.nil?

      # If a chapter is added between chapters
      # if index < @tracks.size && @tracks.size > 0
    else
      tracks_next = @tracks[number - 1]
      new_index = new_index + tracks_next.index
      @duration = @duration + duration_new_chapter unless @duration.nil?
    end

    reindex_tracks(number, duration_new_chapter) if number <= @tracks.size
    renumber_tracks(number) if number <= @tracks.size
    track_new = CueTrack.new(number: number,
                             title: title,
                             performer: performer,
                             composer: composer,
                             index: new_index)
    @tracks.insert(number - 1, track_new)
  end

  private

  def change_chapter_start_index
  end

  def delete_chapter_info

  end

  def erase_chapter

  end

  def reindex_tracks(start_number, added_duration)
    @tracks.each do |track|
      next if track.number < start_number
      track.index + added_duration
    end
  end

  def renumber_tracks(start_number)
    @tracks.each do |track|
      next if track.number < start_number
      track.number += 1
    end
  end

  def raise_duration_cue(number)
    if @duration.nil?
      raise "Total Duration CUE must be set!" +
              "\nReason: Number new chapter > Total chapters count: #{number} > #{@tracks.size}" +
              "\nUnfortunately, CUE does not store the full duration." +
              "\nFor this operation, it must be set e.g: cue.duration = '111:01:10'" +
              "\n\t* And it should also be greater than the index of the last track."
    end
  end

  def raise_duration_chapter(index_next, index_prev)
    if index_next <= index_prev
      raise "Duration chapter too big!" +
              "\nReason: Index next chapter <= Index prev chapter: #{index_next} <= #{index_prev}"
    end
    if (index_next.frames - index_prev.frames) <= 75 * 5
      p 'Attention! You will get a chapter duration less than 5 seconds!'
      p 'Maybe you are doing something wrong.'
    end
  end
end
