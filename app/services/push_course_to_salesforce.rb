# frozen_string_literal: true

#= Enables chat features for a course and adds all participants to course chat channel
class PushCourseToSalesforce
  attr_reader :result

  def initialize(course)
    return unless Features.wiki_ed?
    @course = course
    @salesforce_id = @course.flags[:salesforce_id]
    @client = Restforce.new
    push
  end

  private

  def push
    if @salesforce_id
      update_salesforce_record
    else
      create_salesforce_record
    end
  end

  def create_salesforce_record
    # :create returns the Salesforce id of the new record
    @salesforce_id = @client.create!('Course__c', course_salesforce_fields)
    @course.flags[:salesforce_id] = @salesforce_id
    @course.save
    @result = @salesforce_id
  end

  def update_salesforce_record
    @result = @client.update!('Course__c', { Id: @salesforce_id }.merge(course_salesforce_fields))
  end

  def course_salesforce_fields
    {
      Name: @course.title,
      Course_Page__c: @course.url,
      Course_Dashboard__c: "https://#{ENV['dashboard_url']}/courses/#{@course.slug}",
      Program__c: program_id
    }
  end

  def program_id
    case @course.type
    when 'ClassroomProgramCourse'
      ENV['SF_CLASSROOM_PROGRAM_ID']
    when 'VisitingScholarship'
      ENV['SF_VISITING_SCHOLARS_PROGRAM_ID']
    end
  end
end
