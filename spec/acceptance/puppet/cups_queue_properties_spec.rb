require 'spec_helper_acceptance'

describe 'Custom type `cups_queue`' do
  before(:all) do
    ensure_cups_is_running
  end

  name = 'RSpec&Test_Printer'

  context 'managing any queue' do
    before(:all) do
      purge_all_queues
      add_printers(name)
    end

    context 'changing only the property' do
      context 'access' do
        before(:all) do
          shell("lpadmin -E -p #{Shellwords.escape(name)} -u allow:all")
        end

        context 'with policy => allow' do
          manifest = <<-EOM
            cups_queue { '#{name}':
              ensure => 'printer',
              access => {
                'policy' => 'allow',
                'users'  => ['nina', 'lumbergh', '@council', 'nina'],
              }
            }
          EOM

          it 'applies changes' do
            apply_manifest(manifest, expect_changes: true)
          end

          it 'is idempotent' do
            apply_manifest(manifest, catch_changes: true)
          end
        end

        context 'with policy => allow and changing users' do
          manifest = <<-EOM
            cups_queue { '#{name}':
              ensure => 'printer',
              access => {
                'policy' => 'allow',
                'users'  => ['lumbergh', 'bolton'],
              }
            }
          EOM

          it 'applies changes' do
            apply_manifest(manifest, expect_changes: true)
          end

          it 'is idempotent' do
            apply_manifest(manifest, catch_changes: true)
          end
        end

        context 'with policy => deny' do
          manifest = <<-EOM
            cups_queue { '#{name}':
              ensure => 'printer',
              access => {
                'policy' => 'deny',
                'users'  => ['nina', 'lumbergh', '@council', 'nina'],
              }
            }
          EOM

          it 'applies changes' do
            apply_manifest(manifest, expect_changes: true)
          end

          it 'is idempotent' do
            apply_manifest(manifest, catch_changes: true)
          end
        end

        context 'with policy => deny and changing users' do
          manifest = <<-EOM
            cups_queue { '#{name}':
              ensure => 'printer',
              access => {
                'policy' => 'deny',
                'users'  => ['lumbergh', 'bolton'],
              }
            }
          EOM

          it 'applies changes' do
            apply_manifest(manifest, expect_changes: true)
          end

          it 'is idempotent' do
            apply_manifest(manifest, catch_changes: true)
          end
        end

        context 'unsetting all restrictions' do
          manifest = <<-EOM
            cups_queue { '#{name}':
              ensure => 'printer',
              access => {
                'policy' => 'allow',
                'users'  => ['all'],
              }
            }
          EOM

          it 'applies changes' do
            apply_manifest(manifest, expect_changes: true)
          end

          it 'is idempotent' do
            apply_manifest(manifest, catch_changes: true)
          end
        end
      end

      context 'accepting' do
        before(:all) do
          shell("cupsreject -E #{Shellwords.escape(name)}")
        end

        context '=> true' do
          manifest = <<-EOM
            cups_queue { '#{name}':
              ensure    => 'printer',
              accepting => 'true'
            }
          EOM

          it 'applies changes' do
            apply_manifest(manifest, expect_changes: true)
          end

          it 'sets the correct value' do
            expect(shell("lpoptions -p #{Shellwords.escape(name)}").stdout).to include('printer-is-accepting-jobs=true')
          end

          it 'is idempotent' do
            apply_manifest(manifest, catch_changes: true)
          end
        end

        context '=> false' do
          manifest = <<-EOM
            cups_queue { '#{name}':
              ensure    => 'printer',
              accepting => 'false'
            }
          EOM

          it 'applies changes' do
            apply_manifest(manifest, expect_changes: true)
          end

          it 'sets the correct value' do
            expect(shell("lpoptions -p #{Shellwords.escape(name)}").stdout).to include('printer-is-accepting-jobs=false')
          end

          it 'is idempotent' do
            apply_manifest(manifest, catch_changes: true)
          end
        end
      end

      context 'description' do
        before(:all) do
          shell("lpadmin -E -p #{Shellwords.escape(name)} -D 'color'")
        end

        manifest = <<-EOM
          cups_queue { '#{name}':
            ensure      => 'printer',
            description => 'duplex'
          }
        EOM

        it 'applies changes' do
          apply_manifest(manifest, expect_changes: true)
        end

        it 'sets the correct value' do
          expect(shell("lpoptions -p #{Shellwords.escape(name)}").stdout).to include('printer-info=duplex')
        end

        it 'is idempotent' do
          apply_manifest(manifest, catch_changes: true)
        end
      end

      context 'enabled' do
        before(:all) do
          shell("cupsdisable -E #{Shellwords.escape(name)}")
        end

        context '=> true' do
          manifest = <<-EOM
            cups_queue { '#{name}':
              ensure  => 'printer',
              enabled => 'true'
            }
          EOM

          it 'applies changes' do
            apply_manifest(manifest, expect_changes: true)
          end

          it 'sets the correct value' do
            expect(shell("lpoptions -p #{Shellwords.escape(name)}").stdout).not_to match(/printer-state-reasons=\S*paused\S*/)
          end

          it 'is idempotent' do
            apply_manifest(manifest, catch_changes: true)
          end
        end

        context '=> false' do
          manifest = <<-EOM
            cups_queue { '#{name}':
              ensure  => 'printer',
              enabled => 'false'
            }
          EOM

          it 'applies changes' do
            apply_manifest(manifest, expect_changes: true)
          end

          it 'sets the correct value' do
            expect(shell("lpoptions -p #{Shellwords.escape(name)}").stdout).to match(/printer-state-reasons=\S*paused\S*/)
          end

          it 'is idempotent' do
            apply_manifest(manifest, catch_changes: true)
          end
        end
      end

      context 'held' do
        before(:all) do
          shell("cupsenable -E --release #{Shellwords.escape(name)}")
        end

        context '=> true' do
          manifest = <<-EOM
            cups_queue { '#{name}':
              ensure => 'printer',
              held   => 'true'
            }
          EOM

          it 'applies changes' do
            apply_manifest(manifest, expect_changes: true)
          end

          it 'sets the correct value' do
            expect(shell("lpoptions -p #{Shellwords.escape(name)}").stdout).to match(/printer-state-reasons=\S*hold-new-jobs\S*/)
          end

          it 'is idempotent' do
            apply_manifest(manifest, catch_changes: true)
          end
        end

        context '=> false' do
          manifest = <<-EOM
            cups_queue { '#{name}':
              ensure => 'printer',
              held   => 'false'
            }
          EOM

          it 'applies changes' do
            apply_manifest(manifest, expect_changes: true)
          end

          it 'sets the correct value' do
            expect(shell("lpoptions -p #{Shellwords.escape(name)}").stdout).not_to match(/printer-state-reasons=\S*hold-new-jobs\S*/)
          end

          it 'is idempotent' do
            apply_manifest(manifest, catch_changes: true)
          end
        end
      end

      context 'location' do
        before(:all) do
          shell("lpadmin -E -p #{Shellwords.escape(name)} -L 'Room 451'")
        end

        manifest = <<-EOM
          cups_queue { '#{name}':
            ensure   => 'printer',
            location => 'Room 101'
          }
        EOM

        it 'applies changes' do
          apply_manifest(manifest, expect_changes: true)
        end

        it 'sets the correct value' do
          expect(shell("lpstat -l -p #{Shellwords.escape(name)}").stdout).to include('Room 101')
        end

        it 'is idempotent' do
          apply_manifest(manifest, catch_changes: true)
        end
      end

      context 'options' do
        context 'using native options' do
          before(:all) do
            shell("lpadmin -E -p #{Shellwords.escape(name)}" \
              ' -o auth-info-required=negotiate' \
              ' -o job-sheets-default=banner,banner' \
              ' -o printer-error-policy=retry-current-job')
          end

          manifest = <<-EOM
            cups_queue { '#{name}':
              ensure  => 'printer',
              options => {
                'auth-info-required'   => 'none',
                'printer-error-policy' => 'stop-printer',
                'job-sheets-default'   => 'none,none'
              }
            }
          EOM

          it 'applies changes' do
            apply_manifest(manifest, expect_changes: true)
          end

          it 'is idempotent' do
            apply_manifest(manifest, catch_changes: true)
          end
        end

        context 'using vendor options' do
          before(:all) do
            shell("lpadmin -E -p #{Shellwords.escape(name)} -o Duplex=None -o PageSize=Letter")
          end

          manifest = <<-EOM
            cups_queue { '#{name}':
              ensure  => 'printer',
              options => {
                'Duplex'   => 'DuplexNoTumble',
                'PageSize' => 'A4'
              }
            }
          EOM

          it 'applies changes' do
            apply_manifest(manifest, expect_changes: true)
          end

          it 'sets the correct values' do
            output = shell("lpoptions -p #{Shellwords.escape(name)} -l").stdout
            expect(output).to match(%r{Duplex/.*\s\*DuplexNoTumble\s})
            expect(output).to match(%r{PageSize/.*\s\*A4\s})
          end

          it 'is idempotent' do
            apply_manifest(manifest, catch_changes: true)
          end
        end
      end

      context 'shared' do
        before(:all) do
          shell("lpadmin -E -p #{Shellwords.escape(name)} -o printer-is-shared=false")
        end

        context '=> true' do
          manifest = <<-EOM
            cups_queue { '#{name}':
              ensure => 'printer',
              shared => 'true'
            }
          EOM

          it 'applies changes' do
            apply_manifest(manifest, expect_changes: true)
          end

          it 'is idempotent' do
            apply_manifest(manifest, catch_changes: true)
          end
        end

        context '=> false' do
          manifest = <<-EOM
            cups_queue { '#{name}':
              ensure => 'printer',
              shared => 'false'
            }
          EOM

          it 'applies changes' do
            apply_manifest(manifest, expect_changes: true)
          end

          it 'is idempotent' do
            apply_manifest(manifest, catch_changes: true)
          end
        end
      end
    end
  end
end
