# encoding: utf-8
require 'spec_helper'

describe 'syslog standard filter' do

  before(:all) do
    load_filters <<-CONFIG
      filter {
        #{File.read("src/logstash-filters/snippets/syslog_standard.conf")}
      }
    CONFIG
  end

  describe "Accepting standard syslog message without PID specified" do
    when_parsing_log("@message" => '<85>Apr 24 02:05:03 localhost sudo: bosh_h5156e598 : TTY=pts/0 ; PWD=/var/vcap/bosh_ssh/bosh_h5156e598 ; USER=root ; COMMAND=/bin/pwd') do
      it "parses the log" do
        expect(parsed_result.get("tags")).to eq [ 'syslog_standard' ]
        expect(parsed_result.get("@timestamp").time).to eq Time.iso8601("#{Time.now.year}-04-24T02:05:03.000Z")

        expect(parsed_result.get('@source')['host']).to eq 'localhost'
        expect(parsed_result.get('syslog_hostname')).to eq 'localhost'

        expect(parsed_result.get('syslog_facility')).to eq 'security/authorization'
        expect(parsed_result.get('syslog_facility_code')).to eq 10
        expect(parsed_result.get('syslog_severity')).to eq 'notice'
        expect(parsed_result.get('syslog_severity_code')).to eq 5
        expect(parsed_result.get('syslog_program')).to eq 'sudo'
        expect(parsed_result.get('syslog_pid')).to be_nil
        expect(parsed_result.get('@message')).to eq 'bosh_h5156e598 : TTY=pts/0 ; PWD=/var/vcap/bosh_ssh/bosh_h5156e598 ; USER=root ; COMMAND=/bin/pwd'
      end
    end
  end

  describe "Accepting standard syslog message with PID specified" do
    when_parsing_log("@message" => '<78>Apr 24 04:03:06 localhost crontab[32185]: (root) LIST (root)') do
      it "parses the log" do
        expect(parsed_result.get("tags")).to eq [ 'syslog_standard' ]
        expect(parsed_result.get("@timestamp").time).to eq Time.iso8601("#{Time.now.year}-04-24T04:03:06.000Z")

        expect(parsed_result.get('@source')['host']).to eq 'localhost'
        expect(parsed_result.get('syslog_hostname')).to eq 'localhost'

        expect(parsed_result.get('syslog_facility')).to eq 'clock'
        expect(parsed_result.get('syslog_facility_code')).to eq 9
        expect(parsed_result.get('syslog_severity')).to eq 'informational'
        expect(parsed_result.get('syslog_severity_code')).to eq 6
        expect(parsed_result.get('syslog_program')).to eq 'crontab'
        expect(parsed_result.get('syslog_pid')).to eq '32185'
        expect(parsed_result.get('@message')).to eq '(root) LIST (root)'
      end
    end
  end

  describe "Accepting Cloud Foundry syslog message with valid host" do
    when_parsing_log("@message" => '<14>2014-04-23T23:19:01.227366+00:00 172.31.201.31 vcap.nats [job=vcap.nats index=1]  {\"timestamp\":1398295141.227022}') do
      it "parses the log" do
        expect(parsed_result.get("tags")).to eq [ 'syslog_standard' ]
        expect(parsed_result.get("@timestamp").time).to eq Time.iso8601("2014-04-23T23:19:01.227Z")

        expect(parsed_result.get('@source')['host']).to eq '172.31.201.31'
        expect(parsed_result.get('syslog_hostname')).to eq '172.31.201.31'

        expect(parsed_result.get('syslog_facility')).to eq 'user-level'
        expect(parsed_result.get('syslog_facility_code')).to eq 1
        expect(parsed_result.get('syslog_severity')).to eq 'informational'
        expect(parsed_result.get('syslog_severity_code')).to eq 6
        expect(parsed_result.get('syslog_program')).to eq 'vcap.nats'
        expect(parsed_result.get('syslog_pid')).to be_nil
        expect(parsed_result.get('@message')).to eq '[job=vcap.nats index=1]  {\"timestamp\":1398295141.227022}'
      end
    end
  end

  describe "Invalid syslog message" do
    when_parsing_log("@message" => '<78>Apr 24, this message should fail') do
      it "parses the log" do
        expect(parsed_result.get("tags")).to eq [ 'fail/syslog_standard/_grokparsefailure' ]
      end
    end
  end

  describe "Cloud Foundry loggregator messages" do
    when_parsing_log('@message' => '276 <14>1 2014-05-20T20:40:49+00:00 loggregator d5a5e8a5-9b06-4dd3-8157-e9bd3327b9dc [App/0] - - {"@timestamp":"2014-05-20T20:40:49.907Z","message":"LowRequestRate 2014-05-20T15:44:58.794Z","@source.name":"watcher-bot-ppe","logger":"logsearch_watcher_bot.Program","level":"WARN"}') do
      it "parses the log" do
        expect(parsed_result.get("tags")).to eq [ 'syslog_standard' ]
        expect(parsed_result.get("@timestamp").time).to eq Time.iso8601("2014-05-20T20:40:49Z")

        expect(parsed_result.get('@source')['host']).to eq 'loggregator'
        expect(parsed_result.get('syslog_hostname')).to eq 'loggregator'

        expect(parsed_result.get('syslog_program')).to eq 'd5a5e8a5-9b06-4dd3-8157-e9bd3327b9dc'
        expect(parsed_result.get('syslog6587_msglen')).to eq 276
        expect(parsed_result.get('syslog5424_ver')).to eq 1
        expect(parsed_result.get('syslog_severity_code')).to eq 6
        expect(parsed_result.get('syslog_severity')).to eq 'informational'
        expect(parsed_result.get('syslog_facility_code')).to eq 1
        expect(parsed_result.get('syslog_facility')).to eq 'user-level'

        expect(parsed_result.get('syslog_procid')).to eq '[App/0]'
        expect(parsed_result.get('syslog_msgid')).to eq '-'
        expect(parsed_result.get('@message')).to eq '{"@timestamp":"2014-05-20T20:40:49.907Z","message":"LowRequestRate 2014-05-20T15:44:58.794Z","@source.name":"watcher-bot-ppe","logger":"logsearch_watcher_bot.Program","level":"WARN"}'
      end
    end

    when_parsing_log('@message' => '167 <14>1 2014-05-20T09:46:16+00:00 loggregator d5a5e8a5-9b06-4dd3-8157-e9bd3327b9dc [App/0] - - Updating AppSettings for /home/vcap/app/logsearch-watcher-bot.exe.config') do
      it "parses the log" do
        expect(parsed_result.get("tags")).to eq [ 'syslog_standard' ]
        expect(parsed_result.get("@timestamp").time).to eq Time.iso8601("2014-05-20T09:46:16Z")

        expect(parsed_result.get('@source')['host']).to eq 'loggregator'
        expect(parsed_result.get('syslog_hostname')).to eq 'loggregator'

        expect(parsed_result.get('syslog_program')).to eq 'd5a5e8a5-9b06-4dd3-8157-e9bd3327b9dc'
        expect(parsed_result.get('syslog6587_msglen')).to eq 167
        expect(parsed_result.get('syslog5424_ver')).to eq 1
        expect(parsed_result.get('syslog_severity_code')).to eq 6
        expect(parsed_result.get('syslog_severity')).to eq 'informational'
        expect(parsed_result.get('syslog_facility_code')).to eq 1
        expect(parsed_result.get('syslog_facility')).to eq 'user-level'

        expect(parsed_result.get('syslog_procid')).to eq '[App/0]'
        expect(parsed_result.get('syslog_msgid')).to eq '-'
        expect(parsed_result.get('@message')).to eq 'Updating AppSettings for /home/vcap/app/logsearch-watcher-bot.exe.config'
      end
    end

    when_parsing_log('@message' => '94 <11>1 2014-05-20T09:46:07+00:00 loggregator d5a5e8a5-9b06-4dd3-8157-e9bd3327b9dc [App/0] - -') do
      it "parses the log" do
        expect(parsed_result.get("tags")).to eq [ 'syslog_standard' ]
        expect(parsed_result.get("@timestamp").time).to eq Time.iso8601("2014-05-20T09:46:07Z")

        expect(parsed_result.get('@source')['host']).to eq 'loggregator'
        expect(parsed_result.get('syslog_hostname')).to eq 'loggregator'

        expect(parsed_result.get('syslog_program')).to eq 'd5a5e8a5-9b06-4dd3-8157-e9bd3327b9dc'
        expect(parsed_result.get('syslog6587_msglen')).to eq 94
        expect(parsed_result.get('syslog5424_ver')).to eq 1
        expect(parsed_result.get('syslog_severity_code')).to eq 3
        expect(parsed_result.get('syslog_severity')).to eq 'error'
        expect(parsed_result.get('syslog_facility_code')).to eq 1
        expect(parsed_result.get('syslog_facility')).to eq 'user-level'

        expect(parsed_result.get('syslog_procid')).to eq '[App/0]'
        expect(parsed_result.get('syslog_msgid')).to eq '-'
        expect(parsed_result.get('@message')).to eq '-'
      end
    end
  end

  describe "syslog_sd_params rules" do
    describe "when sd_params.host exists, @shipper.host = syslog_hostname, @source.host = sd_params.host" do
      when_parsing_log("@message" => '<13>1 2015-09-24T11:16:12.808763+01:00 SYSLOG-HOST - - - [NXLOG@14506 host="SDPARAMS-HOST"] IOrderService.ListOpenPositions Duration 8ms') do
        it "parses the log" do
          expect(parsed_result.get("tags")).to eq [ 'syslog_standard' ]

          expect(parsed_result.get('@shipper')['host']).to eq 'SYSLOG-HOST'
          expect(parsed_result.get('@source')['host']).to eq 'SDPARAMS-HOST'
        end
      end
    end

    describe "when sd_params.type exists, @type = sd_params.type, @message = @message" do
      when_parsing_log("@message" => '<13>1 2015-09-24T11:16:12.808763+01:00 SYSLOG-HOST - - - [NXLOG@14506 type="SDPARAMS-TYPE"] IOrderService.ListOpenPositions Duration 8ms') do
        it "parses the log" do
          expect(parsed_result.get("tags")).to eq [ 'syslog_standard' ]

          expect(parsed_result.get('@type')).to eq 'SDPARAMS-TYPE'
          expect(parsed_result.get('@message')).to eq 'IOrderService.ListOpenPositions Duration 8ms'
        end
      end
    end
  end

  describe "NXLOG message" do
    when_parsing_log("@message" => '<13>1 2015-09-24T11:16:12.808763+01:00 PKH-PPE-WEB28 - - - [NXLOG@14506 EventReceivedTime="2015-09-24 11:16:12" SourceModuleName="in_file1" SourceModuleType="im_file" path="\\PKH-PPE-WEB24\\Logs\\TradingApi.log*.log" type="ci_log4net" host="PKH-PPE-WEB24" service="CI WEBSERVICE/TradingAPI" environment="PPE"] INFO  2015-09-24 11:16:12,501 42 CityIndex.TradingApi.Common.Logging.MethodTimeLogger Request 4133629: Action: IOrderService.ListOpenPositions Duration 8ms') do
      it "parses the log" do
        expect(parsed_result.get("tags")).to eq [ 'syslog_standard' ]
        expect(parsed_result.get("@timestamp").time).to eq Time.iso8601("2015-09-24T10:16:12.808Z")

        expect(parsed_result.get('@shipper')['host']).to eq 'PKH-PPE-WEB28'
        expect(parsed_result.get('@source')['host']).to eq 'PKH-PPE-WEB24'
        expect(parsed_result.get('syslog_hostname')).to eq 'PKH-PPE-WEB28'

        expect(parsed_result.get('syslog_sd_id')).to eq 'NXLOG@14506'

        sd_params = parsed_result.get('syslog_sd_params')
        expect(sd_params['EventReceivedTime']).to eq '2015-09-24 11:16:12'
        expect(sd_params['SourceModuleName']).to eq 'in_file1'
        expect(sd_params['SourceModuleType']).to eq 'im_file'
        expect(sd_params['path']).to eq '\PKH-PPE-WEB24\Logs\TradingApi.log*.log'
        expect(sd_params['type']).to eq 'ci_log4net'
        expect(sd_params['host']).to eq 'PKH-PPE-WEB24'
        expect(sd_params['service']).to eq 'CI WEBSERVICE/TradingAPI'
        expect(sd_params['environment']).to eq 'PPE'

        expect(parsed_result.get('@type')).to eq 'ci_log4net'
        expect(parsed_result.get('@message')).to eq 'INFO  2015-09-24 11:16:12,501 42 CityIndex.TradingApi.Common.Logging.MethodTimeLogger Request 4133629: Action: IOrderService.ListOpenPositions Duration 8ms'
      end
    end
  end

  describe "log4net.Appenders.Contrib.RemoteSyslog5424Appender message" do
    when_parsing_log("@message" => '221 <14>1 2015-09-18T13:07:32.553201Z LON-WS01351X G2Shell - - [fields@0 environment="PPE"] INFO  2015-09-18 14:07:32,553 SenderThread RemoteSyslog5424AppenderDiagLogger Connection to the server lost. Re-try in 10 seconds.') do
      it "parses the log" do
        expect(parsed_result.get("tags")).to eq [ 'syslog_standard' ]
        expect(parsed_result.get("@timestamp").time).to eq Time.iso8601("2015-09-18T13:07:32.553Z")

        expect(parsed_result.get('@source')['host']).to eq 'LON-WS01351X'
        expect(parsed_result.get('syslog_hostname')).to eq 'LON-WS01351X'

        expect(parsed_result.get('syslog_sd_id')).to eq 'fields@0'
        expect(parsed_result.get('syslog_sd_params')['environment']).to eq 'PPE'

        expect(parsed_result.get('@message')).to eq 'INFO  2015-09-18 14:07:32,553 SenderThread RemoteSyslog5424AppenderDiagLogger Connection to the server lost. Re-try in 10 seconds.'
      end
    end
  end

  context 'when parsing a sylog message in RFC3164 format from haproxy' do

    before(:all) do
      load_filters <<-CONFIG
        filter {
          #{File.read("src/logstash-filters/snippets/syslog_standard.conf")}
        }
      CONFIG
    end

    when_parsing_log(
      # NOTE: Do not use Jan or Dec here - they are special cases in 'parseAndGuessYear' (see https://github.com/logstash-plugins/logstash-filter-date/blob/master/src/main/java/org/logstash/filters/parser/JodaParser.java#L107-L109)
      '@message' => "<46>Apr 16 15:24:05 haproxy[9252]: 52.62.56.30:45940 [16/Apr/2015:15:24:02.638] syslog-in~ ingestors/node1 328/-1/3332 0 SC 8/8/8/0/3 0/0",
      '@type' => 'syslog'
    ) do

      it "adds the syslog_standard tag" do
        expect(parsed_result.get('tags')).to include("syslog_standard")
      end

      it "extracts the timestamp" do
        expect(parsed_result.get('@timestamp').time).to eq Time.iso8601("#{Time.now.year}-04-16T15:24:05.000Z")
      end

      it "drops the syslog_timestamp field (since it has been captured in @timestamp)" do
        expect(parsed_result.get('syslog_timestamp')).to be_nil
      end

      it "extracts the syslog_program" do
        expect(parsed_result.get('syslog_program')).to eq("haproxy")
      end

      it "extracts the syslog_pid" do
        expect(parsed_result.get('syslog_pid')).to eq("9252")
      end

      it "extracts the syslog_message to @message" do
        expect(parsed_result.get('@message')).to eq("52.62.56.30:45940 [16/Apr/2015:15:24:02.638] syslog-in~ ingestors/node1 328/-1/3332 0 SC 8/8/8/0/3 0/0")
      end
    end
  end
end
