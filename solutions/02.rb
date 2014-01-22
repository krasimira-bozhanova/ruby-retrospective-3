class TodoList
  include Enumerable

  attr_accessor :tasks

  def TodoList.parse(text)
    tasks = text.lines.map do |line|
      status, description, priority, tags = line.split('|', -1).map(&:strip)
      Task.new status, description, priority, tags.split(',').map(&:strip)
    end
    TodoList.new tasks
  end

  def initialize(tasks)
    @tasks = tasks
  end

  def each
    tasks.each { |task| yield task }
  end

  def filter(criteria)
    TodoList.new tasks.select { |task| criteria.matches? task }
  end

  def tasks_todo
    tasks.select { |task| task.status == :todo }.size
  end

  def tasks_in_progress
    tasks.select { |task| task.status == :current }.size
  end

  def tasks_completed
    tasks.select { |task| task.status == :done }.size
  end

  def adjoin(todo_list)
   TodoList.new (tasks + todo_list.tasks).uniq
  end

  def completed?
    tasks.size == tasks_completed
  end
end

class Criteria
  attr_accessor :criterion_block

  class << self
    def status(status)
      Criteria.new { |task| task.status == status }
    end

    def priority(priority)
      Criteria.new { |task| task.priority == priority }
    end

    def tags(tags)
      Criteria.new { |task| task.include_tags? tags }
    end
  end

  def initialize(&criterion_block)
    @criterion_block = criterion_block
  end

  def matches?(task)
    criterion_block.call task
  end

  def &(other)
    Criteria.new { |task| matches? task and other.matches? task }
  end

  def |(other)
    Criteria.new { |task| matches? task or other.matches? task }
  end

  def !
    Criteria.new { |task| not matches? task }
  end
end

class Task
  attr_accessor :status, :description, :priority, :tags

  def initialize(status, description, priority, tags)
    @status = status.downcase.to_sym
    @description = description
    @priority = priority.downcase.to_sym
    @tags = tags
  end

  def include_tags?(possible_tags)
    possible_tags.all? { |tag| tags.include? tag }
  end
end