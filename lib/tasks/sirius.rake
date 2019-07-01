namespace :sirius do

  desc 'Fetches parallels and students from KOSapi, plans stored parallels and rebuilds indexes'
  task :events => %w[
    events:import events:import_students events:plan events:assign_people events:import_exams
    events:import_exam_students events:import_course_events events:import_course_event_students
    events:import_teacher_timetable_slots events:renumber events:reindex
  ]

  task :env do
    require 'bundler'
    Bundler.setup
    require File.expand_path('../../lib/initializer', File.dirname(__FILE__))
    @logger = Logging.logger['sirius.rake']
  end

  namespace :events do

    desc 'Fetches parallels from KOSapi'
    task :import => :env do
      @logger.info 'Importing parallels.'
      build_manager.import_parallels
    end

    desc 'Fetches students from KOSapi'
    task :import_students => :env do
      @logger.info 'Importing students, grab a coffee.'
      build_manager.import_students
    end

    desc 'Plans stored parallels'
    task :plan => :env do
      @logger.info 'Planning parallels.'
      build_manager.plan_stored_parallels
    end

    desc 'Assigns people from parallels to events.'
    task :assign_people => :env do
      @logger.info 'Assigning people to events.'
      build_manager.assign_people
    end

    desc 'Imports exams from KOSapi and generates corresponding events.'
    task :import_exams => :env do
      @logger.info 'Importing exams.'
      build_manager.import_exams
    end

    desc 'Import students for saved exam events for all active semesters.'
    task :import_exam_students => :env do
      @logger.info 'Importing exam students.'
      build_manager.import_exam_students
    end

    desc 'Import course events for all active semesters.'
    task :import_course_events => :env do
      @logger.info 'Importing course events.'
      build_manager.import_course_events
    end

    desc 'Import course event students for all active semesters.'
    task :import_course_event_students => :env do
      @logger.info 'Importing course event students.'
      build_manager.import_course_event_students
    end

    desc 'Import teacher timetable slots for active semesters.'
    task :import_teacher_timetable_slots => :env do
      @logger.info 'Importing teacher timetable slots.'
      build_manager.import_teacher_timetable_slots
    end

    desc 'Recalculates relative sequence number for all existing non-deleted events in active semesters.'
    task :renumber => :env do
      @logger.info 'Renumbering events.'
      build_manager.renumber_events
    end

    desc 'Reset and reimport search indexes'
    task :reindex => :env do
      begin
        Rake::Task['indexes:reset'].invoke
      rescue StandardError => err
        @logger.error "Failed to reindex events: #{err}"
      end
    end
  end


  namespace :semesters do

    task :create => :env do
      require 'sirius/load_semesters'  # TODO
    end
  end

end

def build_manager
  require 'sirius/schedule_manager'
  Sirius::ScheduleManager.new
end
