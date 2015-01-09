require 'json'
require 'date'

module NexusCli
  # @author Leo Simons <lsimons@schubergphilis.com>
  module TaskActions

    # Gets information about the current Nexus scheduled tasks.
    #
    # @param  header a header to send with the request (Accept: application/xml by default)
    # @return [String] a String of XML with data about Nexus tasks
    def get_tasks(header=XML_ACCEPT_HEADER)
      response = nexus.get(nexus_url("service/local/schedules"), :header => header)
      case response.status
        when 200
          return response.content
        else
          raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    def create_download_indexes_task(name, schedule='daily', enabled=true, start_date=nil, recurring_time=nil,
                                     repository_id='all_repo')
      params = common_task_params('DownloadIndexesTask', enabled, name, recurring_time, schedule, start_date,
                                  repository_id)
      create_task(params)
    end

    # Creates a new scheduled task to empty the trash.
    #
    # @param  name the name to give to the task
    # @param  schedule, the schedule to use ('cron', 'daily', 'hourly', 'manual', 'monthly', 'now', 'once', 'weekly'),
    #     defaults to daily
    # @param  enabled whether the task is scheduled to run
    # @param  start_date what date the task should first run (millis since epoch), defaults to today
    # @param  recurring_time what time of day the task should recur, defaults to 00:00
    # @param  repository_id what repository or group the task should run for, defaults to 'all_repo' which specifies
    #     running for all repositories
    # @param  older_than_days how old items in the trash must be before being deleted by this task
    # @return true if the task was created, raises an error otherwise
    def create_empty_trash_task(name, schedule='daily', enabled=true, start_date=nil, recurring_time=nil,
                                repository_id='all_repo', older_than_days=10)
      params = common_task_params('EmptyTrashTask', enabled, name, recurring_time, schedule, start_date,
                                  repository_id)
      params[:properties] << to_property('EmptyTrashItemsOlderThan', older_than_days)
      create_task(params)
    end

    # noinspection RubyInstanceMethodNamingConvention
    def create_download_nuget_feed_task(name, schedule='daily', enabled=true, start_date=nil, recurring_time=nil,
                                        repository_id='all_repo', clear_cache=false, all_versions=false, retries=3)
      params = common_task_params('DownloadNugetFeedTask', enabled, name, recurring_time, schedule, start_date,
                                  repository_id)
      params[:properties] << to_property('clearCache', clear_cache)
      params[:properties] << to_property('allVersions', all_versions)
      params[:properties] << to_property('retries', retries)
      create_task(params)
    end

    def create_optimize_index_task(name, schedule='daily', enabled=true, start_date=nil, recurring_time=nil,
                                   repository_id='all_repo')
      params = common_task_params('OptimizeIndexTask', enabled, name, recurring_time, schedule, start_date,
                                  repository_id)
      create_task(params)
    end

    def create_publish_indexes_task(name, schedule='daily', enabled=true, start_date=nil, recurring_time=nil,
                                    repository_id='all_repo')
      params = common_task_params('PublishIndexesTask', enabled, name, recurring_time, schedule, start_date,
                                  repository_id)
      create_task(params)
    end

    def create_repair_index_task(name, schedule='daily', enabled=true, start_date=nil, recurring_time=nil,
                                 repository_id='all_repo')
      # [resourceStorePath]
      params = common_task_params('RepairIndexTask', enabled, name, recurring_time, schedule, start_date,
                                  repository_id)
      create_task(params)
    end

    def create_update_index_task(name, schedule='daily', enabled=true, start_date=nil, recurring_time=nil,
                                 repository_id='all_repo')
      # [resourceStorePath]
      params = common_task_params('UpdateIndexTask', enabled, name, recurring_time, schedule, start_date,
                                  repository_id)
      create_task(params)
    end

    def create_snapshot_remover_task(name, schedule='daily', enabled=true, start_date=nil, recurring_time=nil,
                                     repository_id='all_repo', min_snapshots=10, remove_older=10,
                                     remove_if_release=false, grace_after_release=nil, delete_immediately=false)
      params = common_task_params('SnapshotRemoverTask', enabled, name, recurring_time, schedule, start_date,
                                  repository_id)
      if not min_snapshots.nil? and min_snapshots >= 0
        params[:properties] << to_property('minSnapshotsToKeep', min_snapshots)
      end
      if not remove_older.nil? and remove_older >= 0
        params[:properties] << to_property('removeOlderThanDays', remove_older)
      end
      unless remove_if_release.nil?
        params[:properties] << to_property('removeIfReleaseExists', remove_if_release)
        if not grace_after_release.nil? and grace_after_release > 0
          params[:properties] << to_property('graceDaysAfterRelease', grace_after_release)
        end
      end
      params[:properties] << to_property('deleteImmediately', delete_immediately)
      create_task(params)
    end

    # exist but aren't mapped...
    #
    # EvictUnusedProxiedItemsTask, number
    # ExpireCacheTask, [resourceStorePath]
    # PurgeBrokenRubygemsMetadataTask
    # PurgeTimeline, purgeOlderThan
    # PurgeApiKeysTask
    # ReleaseRemoverTask, numberOfVersionsToKeep, [repositoryTarget]
    # UnusedSnapshotRemoverTask, daysSinceLastRequested
    # RebuildRubygemsMetadataTask
    # SyncRubygemsMetadataTask
    # SynchronizeShadowsTask
    # RebuildMavenMetadataTask, [resourceStorePath]
    # RebuildNugetFeedTask, [resourceStorePath]
    # GenerateMetadataTask, repoId, repoDir, []singleRpmPerDir], [forcEfullScan]

    # Creates a new scheduled task.
    #
    # @param  params the parameters from which to create the task
    # @return true if the task was created, raises an error otherwise
    def create_task(params)
      json = JSON.dump(:data => params)
      response = nexus.post(nexus_url("service/local/schedules"), :body => json, :header => DEFAULT_CONTENT_TYPE_HEADER)
      case response.status
        when 200
          return true
        when 201
          return true
        when 400
          raise CreateTaskException.new(response.content)
        when 503
          raise CouldNotConnectToNexusException
        else
          raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    # Deletes the given task
    # 
    # @param  name [String] the name of the task to delete
    #
    # @return [Boolean] true if the task is deleted, raises an error otherwise
    def delete_task(name)
      json = get_tasks(header=DEFAULT_ACCEPT_HEADER)
      parsed = JSON::parse(json)
      data = parsed['data']
      tasks = if data.nil?
                []
              elsif data.is_a? Hash
                [data]
              elsif data.is_a? Array
                data
              else
                raise TaskParseException.new(json)
              end
      deleted = false
      tasks.each do |task|
        if task['name'] == name
          delete_task_by_id(task['id'])
          deleted = true
        end
      end
      unless deleted
        raise TaskDoesNotExistException
      end
      true
    end
  
    def delete_task_by_id(id)
      response = nexus.delete(nexus_url("service/local/schedules/#{id}"))
      case response.status
        when 204
          return true
        when 404
          raise TaskDoesNotExistException
        when 503
          raise CouldNotConnectToNexusException
        else
          raise UnexpectedStatusCodeException.new(response.status)
      end
    end

    private

    def common_task_params(type, enabled, name, recurring_time, schedule, start_date, repository_id)
      params = {}
      params[:typeId] = type
      params[:properties] = []
      params[:name] = name
      params[:schedule] = schedule
      params[:enabled] = enabled
      params[:startDate] = to_date_param(start_date)
      params[:recurringTime] = to_time_param(recurring_time)
      params[:properties] << to_repository_property(repository_id)
      params
    end

    def to_repository_property(repository_id)
      to_property('repositoryId',
                  if repository_id.nil?
                    'all_repo'
                  else
                    sanitize_for_id(repository_id)
                  end
      )
    end

    # noinspection RubyStringKeysInHashInspection
    def to_property(key, value)
      {'key' => key, 'value' => value}
    end

    def to_time_param(recurring_time)
      if recurring_time.nil?
        '00:00'
      else
        recurring_time
      end
    end

    def to_date_param(start_date)
      if start_date.nil?
        now = Time.now
        today = Time.utc(now.year, now.month, now.day)
        (today.to_i * 1000).to_s
      elsif start_date.is_a? String
        if start_date =~ /^[0-9]{15}$/
          start_date
        else
          Date.parse(start_date).strftime('%Q')
        end
      else
        start_date
      end
    end
  end
end
