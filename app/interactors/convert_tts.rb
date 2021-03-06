require 'interpipe/interactor'

class ConvertTTS
  include Interpipe::Interactor

  DB_KEYS = [:day, :duration, :first_hour, :parity]

  def setup
    @rooms = {}
  end

  def perform(timetable_slots:, rooms:, **options)
    @rooms = build_rooms_hash(rooms)
    @options = options
    @timetable_slots = timetable_slots.map do |parallel_id, slots|
      slots.reject {|slot| not valid?(slot) }.map { |slot| convert_slot(slot, parallel_id) }
    end.flatten
  end

  def results
    {
        timetable_slots: @timetable_slots
    }.merge(@options)
  end

  private
  def build_rooms_hash(rooms)
    Hash[rooms.map{|room| [room.kos_code, room]}]
  end

  def convert_slot(slot, parallel_id)
    room_code = slot.room.link_id if slot.room
    slot_hash = slot.to_hash
    slot_hash = slot_hash.select { |key,_| DB_KEYS.include? key }
    TimetableSlot.new(slot_hash) do |s|
      s.id = slot.id
      s.parallel_id = parallel_id
      s.room = @rooms[room_code] if room_code
      s.deleted_at = nil
      s.start_time = slot.start_time
      s.end_time = slot.end_time
      s.weeks = convert_weeks_to_ranges(slot.weeks) if slot.weeks
    end
  end

  def valid?(slot)
    slot.day != nil
  end

  def convert_weeks_to_ranges(weeks)
    weeks.split(',').map do |str|
      from, to = str.split('-', 2)
      Range.new(Integer(from), Integer(to || from))
    end
  end

end
