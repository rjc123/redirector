require 'redirector'

desc 'Add a new site to data/sites'
task :new_site, [:abbr, :whitehall_slug, :host] do |_, args|
  errors = [:abbr, :whitehall_slug, :host].inject([]) do |errors, arg|
    args.send(arg).nil? ? errors << arg : errors
  end

  unless errors.empty?
    puts "#{errors.map { |e| e.to_s }.join(',')} required.\n"\
         "Usage:\n\trake new_site[abbr,whitehall_slug,host]"
    exit
  end

  site = Redirector::Site.create(args.abbr, args.whitehall_slug, args.host)
  site.save!

  Redirector::Mappings.create_default(args.abbr)
  Redirector::Tests.create_default(args)

  puts site.filename
end