require 'spec_helper'
require 'models/timetable_slot'

describe TimetableSlot do

  describe '.from_kosapi' do
    let(:parallel) { Fabricate(:parallel) }
    let(:room) { double(href: '432', title: 'A-1442') }
    let(:kosapi_slot) { double(to_hash: {id: 1234, day: 4, duration: 2, first_hour: 3, parity: :odd }, room: room ) }

    it 'converts kosapi timetable slot to sirius timetable slot entity' do
      slot = TimetableSlot.from_kosapi(kosapi_slot, parallel)
      expect(slot).to be_an_instance_of(TimetableSlot)
      expect(slot.id).to eq 1234
      expect(slot.day).to eq :thursday
      expect(slot.duration).to eq 2
      expect(slot.first_hour).to eq 3
      expect(slot.parity).to eq :odd
    end

    context 'with room record not existing' do
      it 'creates related room record' do
        slot = TimetableSlot.from_kosapi(kosapi_slot, parallel)
        expect(slot.room.id).not_to be_nil
        expect(slot.room.kos_code).to eq 'A-1442'
      end
    end

    context 'with room record existing' do
      let!(:db_room) { Fabricate(:room, kos_code: 'A-1442') }

      it 'finds related room record' do
        slot = TimetableSlot.from_kosapi(kosapi_slot, parallel)
        expect(slot.room.id).to eq db_room.id
        expect(slot.room.kos_code).to eq 'A-1442'
      end
    end

    context 'with invalid room code' do
      let(:room) { double(href: '432', title: 'no-title') }

      it 'skips room when invalid' do
        slot = TimetableSlot.from_kosapi(kosapi_slot, parallel)
        expect(slot.room).to be_nil
      end
    end

  end

end
