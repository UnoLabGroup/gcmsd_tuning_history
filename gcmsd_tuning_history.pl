use strict;
use warnings;
use Text::CSV;
use Time::Piece;
use File::Spec;


# To generate standalone executable (written for .exe on Windows 11)
# Need "PAR::Packer" perl Perl module
# pp -M Text::CSV_XS -a "bin/pdftotext.exe" -o gcmsd_tuning_history.exe gcmsd_tuning_history.pl


# Execute script from main subroutine
main(@ARGV);


sub get_data_lines {
	
	my ($line_match, @text) = @_;
	
	foreach my $row (@text) {
		if ($line_match eq @$row[0]) {
			next if (($line_match eq 'Repeller') && (@$row[2] eq 'Amu'));
			next if (($line_match eq 'Ion') && (@$row[1] eq 'Polarity'));
			next if (($line_match eq 'Ion') && (@$row[1] eq 'Focus'));
			next if (($line_match eq '69.00') && (@$row == 4));
			
			return @$row;
		}
	}
}


sub get_report_data {
	
	my ($report) = @_;
	
	my $binary_path;
	if ($ENV{PAR_TEMP}) {
		$binary_path = File::Spec->catfile($ENV{PAR_TEMP}, 'inc', 'bin', 'pdftotext.exe');
	} else {
		$binary_path = 'bin/pdftotext.exe';
	}
	
	my $report_text = `$binary_path -enc UTF-8 -raw "$report" -`;
	my @text_lines = split /\n/, $report_text;
	
	my $line_num = 0;
	my $data_num = 0;
	my @line_items = ();
	my @data = ();
	my @line_matches = (
		"Report",
		"Filament",
		"69.00",
		"219.00",
		"502.00",
		"Air/Water",
		"Column(1)",
		"Ion",
		"Repeller"
	);
	
	foreach my $line (@text_lines[0 .. $#text_lines -1]) {
		my @line_text = split(' ', $line);
		# print "$line_num @line_text\n";
		push @line_items, [ @line_text ];
		$line_num += 1;
	}
	
	foreach my $match (@line_matches) {
		my @data_line = get_data_lines($match, @line_items);
		push @data, [ @data_line ];
		# print "$data_num " . "@data_line\n";
		$data_num += 1;
	}
	
	# foreach my $row (@data) {
		# print "@$row\n";
	# }
	
	return @data;
}


sub get_tune_files {
	
	my @reports_all = glob("*.pdf");
	my @tune_reports = ();
	
	foreach my $report (@reports_all) {
		if (substr($report, 0, 5) eq 'atune') {
			push(@tune_reports, $report);
		} elsif (substr($report, 0, 5) eq 'etune') {
			push(@tune_reports, $report);
		}
	}
	
	return @tune_reports;
}


sub format_report_data {
	
	my ($report) = @_;
	my @report_data = get_report_data($report);

	# Define data for all columns
	my @report_data_formatted = (
		$report_data[0][2],  # date created
		$report,  # report filename
		$report_data[1][1],  # filament number
		@{ $report_data[2] },  # target mass 69 table row
		@{ $report_data[3] },  # target mass 219 table row
		@{ $report_data[4] },  # target mass 502 table row
		$report_data[5][3],  # H2O
		$report_data[5][5],  # N2
		$report_data[5][7],  # O2
		$report_data[5][9],  # CO2
		$report_data[5][11],  # N2/H2O
		$report_data[6][2],  # column(1) flow
		$report_data[6][4],  # column(2) flow
		$report_data[6][8],  # interface temp
		$report_data[7][5],  # EM volts
		$report_data[8][9]  # gain factor
	);
	
	return @report_data_formatted;
}


sub main {
	
	my (@args) = @_;
	
	# Debug: List of specific filenames
	# my @reports = ('atune_240227.pdf');
	my @reports = get_tune_files();
	
	my @column_names = (
		"Date",
		"Filename",
		"Filament"
	);
	my @mz_headers = (
		"Target_mz",
		"Actual_mz",
		"Abund",
		"Rel_Abund",
		"Iso_mz",
		"Iso_Abund",
		"Iso_Ratio"
	);
	my @column_names2 = (
		"H2O",
		"N2",
		"O2",
		"CO2",
		"N2/H2O",
		"Column_1_Flow",
		"Column_2_Flow",
		"Interface_Temp",
		"EM Volts",
		"Gain Factor"
	);
	push(@column_names, @mz_headers, @mz_headers, @mz_headers, @column_names2);
	
	my $date = localtime->strftime('%Y%m%d');
	my $csv_filename = $date . '_tune_report_history.csv';
	
	# Rewrite to account for multiple file versions
	# if (-e $csv_filename) {
		# die "$csv_filename already exists. Please rename or remove it from this folder before re-running this program.";
	# }
	
	my $csv = Text::CSV->new({
		binary    => 1,
		auto_diag => 1,
		eol       => "\n"
	});
	
	open my $fh, '>:encoding(UTF-8)', $csv_filename
		or die "Could not open '$csv_filename': $!";
	
	$csv->say($fh, \@column_names);
	
	foreach my $report (@reports) {
		print "Loading: $report\n";
		
		my @report_data = format_report_data($report);
		$csv->say($fh, \@report_data);
		
		print "Success: $report\n";
	}
	
	close $fh;
	print "Completed!\n";
	
	return 0;
}