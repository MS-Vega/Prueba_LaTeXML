# Parche editorial para LaTeXML::Post::MakeBibliography
# Formato: "Autores. Título. Editorial, año, págs. X-Y."
package LaTeXML::Post::MakeBibliography;
no warnings 'redefine';

sub do_year_plain {
  my (@stuff) = @_;
  return (@stuff, @LaTeXML::Post::MakeBibliography::SUFFIX); }

# "págs. " como cadena Unicode, para que se escriba bien en el HTML
my $PAGS = "p\x{e1}gs. ";
utf8::upgrade($PAGS);

foreach my $type (keys %FMT_SPEC) {
  my $blocks = $FMT_SPEC{$type};
  next unless ref($blocks) eq 'ARRAY' && @$blocks > 1;
  my $first = $blocks->[0];
  next unless grep { ($_->[3] // '') eq 'year' } @$first;
  # último bloque (no el primero) que lleva el punto final
  my ($target) = grep { my $b = $_; grep { ($_->[0] // '') eq 'true' } @$b }
    reverse @{$blocks}[1 .. $#{$blocks}];
  next unless $target;
  my ($i) = grep { ($target->[$_]->[0] // '') eq 'true' } 0 .. $#{$target};
  my $tienepags = grep { my $b = $_; grep { ($_->[0] // '') =~ /role="pages"/ } @$b } @$blocks;
  my @nuevas = (['ltx:bib-date[@role="publication"]', ', ', '', 'year', \&do_year_plain, '']);
  push(@nuevas, ['ltx:bib-part[@role="pages"]', ', ', $PAGS, 'pages', \&do_any, ''])
    unless $tienepags;
  splice(@$target, $i, 0, @nuevas);
  @$first = grep { ($_->[3] // '') ne 'year' } @$first;
  push(@$first, ['true', '.']);
}

# Para que no se referencie todo el documento
sub _solo_nocite {
  my ($doc, $id) = @_;
  my ($n) = $doc->findnodes("//*[\@xml:id='$id']");
  return 0 unless $n;
  my @nada  = $doc->findnodes('descendant::ltx:bibref[@show="nothing"]', $n);
  my @citas = $doc->findnodes('descendant::ltx:bibref[not(@show="nothing")]', $n);
  return (@nada && !@citas) ? 1 : 0; }

1;
