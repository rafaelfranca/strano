require 'kernel'
class Job < ActiveRecord::Base

  belongs_to :project
  belongs_to :user
  after_create :execute_task

  default_scope order('created_at DESC')
  default_scope where(:deleted_at => nil)


  def self.deleted
    self.unscoped.where 'deleted_at IS NOT NULL'
  end


  def run_task
    status, stdout_output, stderr_output = nil, "", ""
    command = "bundle exec cap -f Capfile -Xx -l STDOUT #{stage} #{task}"

    FileUtils.chdir project.repo.path do
      status = Open4::popen4 command do |pid, stdin, stdout, stderr|
        stdin.close

        stdout_output += "Running: '#{command}'...\n\n"
        stdout_output += stdout.read.strip
        stderr_output += stderr.read.strip
      end
    end

    if status.exitstatus != 0
      stderr_output
    else
      stdout_output
    end
  end

  def complete?
    !completed_at.nil?
  end


  private

    def execute_task
      Resque.enqueue CapExecute, id
    end

end
