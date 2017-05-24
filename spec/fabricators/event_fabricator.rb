require 'sequel/extensions/pg_array'
require 'models/event'

Fabricator(:event) do
  name { {cs: 'Event name'} }
  note { {cs: 'Event note'} }
  starts_at DateTime.parse('2014-04-05 14:30')
  ends_at DateTime.parse('2014-04-05 16:00')
  teacher_ids ['vomackar']
  student_ids ['skocdpet']
  event_type 'lecture'
  deleted false
  faculty 18_000
  semester 'B141'
  capacity 20
  source_type 'timetable_slot'
end

Fabricator(:full_event, from: :event) do
  course
  transient teachers: 1, students: 2
  teacher_ids { |tr| Fabricate.times(tr[:teachers], :person).map{|person| person.id} }
  student_ids { |tr| Fabricate.times(tr[:students], :person).map{|person| person.id} }
end
