
global test_file_analysis_source: string = "" &redef;

global test_file_actions: set[FileAnalysis::ActionArgs];

global test_get_file_name: function(f: fa_file): string =
	function(f: fa_file): string { return ""; } &redef;

global test_print_file_data_events: bool = F &redef;

event file_chunk(f: fa_file, data: string, off: count)
	{
	if ( test_print_file_data_events )
		print "file_chunk", f$id, |data|, off, data;
	}

event file_stream(f: fa_file, data: string)
	{
	if ( test_print_file_data_events )
		print "file_stream", f$id, |data|, data;
	}

hook FileAnalysis::policy(trig: FileAnalysis::Trigger, f: fa_file)
	{
	print trig;

	switch ( trig ) {
	case FileAnalysis::TRIGGER_NEW:
		print f$id, f$seen_bytes, f$missing_bytes;

		if ( test_file_analysis_source == "" ||
		     f$source == test_file_analysis_source )
			{
			for ( act in test_file_actions )
				FileAnalysis::add_action(f, act);

			local filename: string = test_get_file_name(f);
			if ( filename != "" )
				FileAnalysis::add_action(f,
				                         [$act=FileAnalysis::ACTION_EXTRACT,
				                          $extract_filename=filename]);
			FileAnalysis::add_action(f,
			                         [$act=FileAnalysis::ACTION_DATA_EVENT,
			                          $chunk_event=file_chunk,
			                          $stream_event=file_stream]);

			}
		break;

	case FileAnalysis::TRIGGER_BOF_BUFFER:
		if ( f?$bof_buffer )
			print f$bof_buffer[0:10];
		break;

	case FileAnalysis::TRIGGER_TYPE:
		# not actually printing the values due to libmagic variances
		if ( f?$file_type )
			print "file type is set";
		if ( f?$mime_type )
			print "mime type is set";
		break;
	}
	}

event file_state_remove(f: fa_file)
	{
	print "FILE_STATE_REMOVE";
	print f$id, f$seen_bytes, f$missing_bytes;
	if ( f?$conns )
		for ( cid in f$conns )
			print cid;

	if ( f?$total_bytes )
		print "total bytes: " + fmt("%s", f$total_bytes);
	if ( f?$source )
		print "source: " + f$source;

	if ( ! f?$info ) return;

	if ( f$info?$md5 )
		print fmt("MD5: %s", f$info$md5);
	if ( f$info?$sha1 )
		print fmt("SHA1: %s", f$info$sha1);
	if ( f$info?$sha256 )
		print fmt("SHA256: %s", f$info$sha256);
	}

hook FileAnalysis::policy(trig: FileAnalysis::Trigger, f: fa_file)
	&priority=-5
	{
	if ( trig != FileAnalysis::TRIGGER_TYPE ) return;

	# avoids libmagic variances across systems
	if ( f?$mime_type )
		f$mime_type = "set";
	if ( f?$file_type )
		f$file_type = "set";
	}

event bro_init()
	{
	add test_file_actions[[$act=FileAnalysis::ACTION_MD5]];
	add test_file_actions[[$act=FileAnalysis::ACTION_SHA1]];
	add test_file_actions[[$act=FileAnalysis::ACTION_SHA256]];
	}
