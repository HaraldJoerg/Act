#!perl

use strict;
use Test::More tests => 4325;
use DBI;
use Act::Config;
use Act::Country;

$Request{dbh} = DBI->connect(
    $Config->database_dsn,
    $Config->database_user,
    $Config->database_passwd,
);
$Config->set(default_language => 'en');

# get list of currently needed languages
my %languages;
for my $conf (keys %{$Config->conferences}) {
    my $cfg = Act::Config::get_config($conf);
    $languages{$_} = 1 for sort keys %{$cfg->languages};
}
my @languages = sort keys %languages;

my (%expected, %found, %seen);
# list of expected countries, from ISO-3166
while (<DATA>) {
    chomp;
    next if /^#/;
    my ($name, $code) = split /;/;
    $expected{lc $code} = $name;
}

# countries from our database
for my $language (@languages) {
    $Request{language} = $language;
    my $c = Act::Country::CountryNames;
    isa_ok($c, 'ARRAY');
    for my $p (@$c) {
        isa_ok($p, 'HASH');
        like( $p->{iso}, qr/^[a-z]{2}$/, "$p->{name} iso" );
        ok($p->{name}, "$p->{name} $language");
        if ($p->{iso} &&!$seen{$p->{iso}}++) {
            ok(exists $expected{$p->{iso}}, "$p->{iso} is in iso-3166");
        }
        ++$found{$p->{iso}}{$language} if $p->{iso};
    }
}

# ensure we have names in all required languages
for my $code (sort keys %found) {
    my @missing = grep !exists $found{$code}{$_}, @languages;
    ok(!@missing, "$code missing in @missing");
}

# iso3166 codes not in our database
for my $code (sort keys %expected) {
    ok(exists $found{$code}, "iso-3166 $code in database");
}

__DATA__
# get this from http://www.iso.org/iso/en/prods-services/iso3166ma/02iso-3166-code-lists/list-en1-semic.txt
AFGHANISTAN;AF
�LAND ISLANDS;AX
ALBANIA;AL
ALGERIA;DZ
AMERICAN SAMOA;AS
ANDORRA;AD
ANGOLA;AO
ANGUILLA;AI
ANTARCTICA;AQ
ANTIGUA AND BARBUDA;AG
ARGENTINA;AR
ARMENIA;AM
ARUBA;AW
AUSTRALIA;AU
AUSTRIA;AT
AZERBAIJAN;AZ
BAHAMAS;BS
BAHRAIN;BH
BANGLADESH;BD
BARBADOS;BB
BELARUS;BY
BELGIUM;BE
BELIZE;BZ
BENIN;BJ
BERMUDA;BM
BHUTAN;BT
BOLIVIA;BO
BOSNIA AND HERZEGOVINA;BA
BOTSWANA;BW
BOUVET ISLAND;BV
BRAZIL;BR
BRITISH INDIAN OCEAN TERRITORY;IO
BRUNEI DARUSSALAM;BN
BULGARIA;BG
BURKINA FASO;BF
BURUNDI;BI
CAMBODIA;KH
CAMEROON;CM
CANADA;CA
CAPE VERDE;CV
CAYMAN ISLANDS;KY
CENTRAL AFRICAN REPUBLIC;CF
CHAD;TD
CHILE;CL
CHINA;CN
CHRISTMAS ISLAND;CX
COCOS (KEELING) ISLANDS;CC
COLOMBIA;CO
COMOROS;KM
CONGO;CG
CONGO, THE DEMOCRATIC REPUBLIC OF THE;CD
COOK ISLANDS;CK
COSTA RICA;CR
COTE D'IVOIRE;CI
CROATIA;HR
CUBA;CU
CYPRUS;CY
CZECH REPUBLIC;CZ
DENMARK;DK
DJIBOUTI;DJ
DOMINICA;DM
DOMINICAN REPUBLIC;DO
ECUADOR;EC
EGYPT;EG
EL SALVADOR;SV
EQUATORIAL GUINEA;GQ
ERITREA;ER
ESTONIA;EE
ETHIOPIA;ET
FALKLAND ISLANDS (MALVINAS);FK
FAROE ISLANDS;FO
FIJI;FJ
FINLAND;FI
FRANCE;FR
FRENCH GUIANA;GF
FRENCH POLYNESIA;PF
FRENCH SOUTHERN TERRITORIES;TF
GABON;GA
GAMBIA;GM
GEORGIA;GE
GERMANY;DE
GHANA;GH
GIBRALTAR;GI
GREECE;GR
GREENLAND;GL
GRENADA;GD
GUADELOUPE;GP
GUAM;GU
GUATEMALA;GT
GUINEA;GN
GUINEA-BISSAU;GW
GUYANA;GY
HAITI;HT
HEARD ISLAND AND MCDONALD ISLANDS;HM
HOLY SEE (VATICAN CITY STATE);VA
HONDURAS;HN
HONG KONG;HK
HUNGARY;HU
ICELAND;IS
INDIA;IN
INDONESIA;ID
IRAN, ISLAMIC REPUBLIC OF;IR
IRAQ;IQ
IRELAND;IE
ISRAEL;IL
ITALY;IT
JAMAICA;JM
JAPAN;JP
JORDAN;JO
KAZAKHSTAN;KZ
KENYA;KE
KIRIBATI;KI
KOREA, DEMOCRATIC PEOPLE'S REPUBLIC OF;KP
KOREA, REPUBLIC OF;KR
KUWAIT;KW
KYRGYZSTAN;KG
LAO PEOPLE'S DEMOCRATIC REPUBLIC;LA
LATVIA;LV
LEBANON;LB
LESOTHO;LS
LIBERIA;LR
LIBYAN ARAB JAMAHIRIYA;LY
LIECHTENSTEIN;LI
LITHUANIA;LT
LUXEMBOURG;LU
MACAO;MO
MACEDONIA, THE FORMER YUGOSLAV REPUBLIC OF;MK
MADAGASCAR;MG
MALAWI;MW
MALAYSIA;MY
MALDIVES;MV
MALI;ML
MALTA;MT
MARSHALL ISLANDS;MH
MARTINIQUE;MQ
MAURITANIA;MR
MAURITIUS;MU
MAYOTTE;YT
MEXICO;MX
MICRONESIA, FEDERATED STATES OF;FM
MOLDOVA, REPUBLIC OF;MD
MONACO;MC
MONGOLIA;MN
MONTSERRAT;MS
MOROCCO;MA
MOZAMBIQUE;MZ
MYANMAR;MM
NAMIBIA;NA
NAURU;NR
NEPAL;NP
NETHERLANDS;NL
NETHERLANDS ANTILLES;AN
NEW CALEDONIA;NC
NEW ZEALAND;NZ
NICARAGUA;NI
NIGER;NE
NIGERIA;NG
NIUE;NU
NORFOLK ISLAND;NF
NORTHERN MARIANA ISLANDS;MP
NORWAY;NO
OMAN;OM
PAKISTAN;PK
PALAU;PW
PALESTINIAN TERRITORY, OCCUPIED;PS
PANAMA;PA
PAPUA NEW GUINEA;PG
PARAGUAY;PY
PERU;PE
PHILIPPINES;PH
PITCAIRN;PN
POLAND;PL
PORTUGAL;PT
PUERTO RICO;PR
QATAR;QA
REUNION;RE
ROMANIA;RO
RUSSIAN FEDERATION;RU
RWANDA;RW
SAINT HELENA;SH
SAINT KITTS AND NEVIS;KN
SAINT LUCIA;LC
SAINT PIERRE AND MIQUELON;PM
SAINT VINCENT AND THE GRENADINES;VC
SAMOA;WS
SAN MARINO;SM
SAO TOME AND PRINCIPE;ST
SAUDI ARABIA;SA
SENEGAL;SN
SERBIA AND MONTENEGRO;CS
SEYCHELLES;SC
SIERRA LEONE;SL
SINGAPORE;SG
SLOVAKIA;SK
SLOVENIA;SI
SOLOMON ISLANDS;SB
SOMALIA;SO
SOUTH AFRICA;ZA
SOUTH GEORGIA AND THE SOUTH SANDWICH ISLANDS;GS
SPAIN;ES
SRI LANKA;LK
SUDAN;SD
SURINAME;SR
SVALBARD AND JAN MAYEN;SJ
SWAZILAND;SZ
SWEDEN;SE
SWITZERLAND;CH
SYRIAN ARAB REPUBLIC;SY
TAIWAN, PROVINCE OF CHINA;TW
TAJIKISTAN;TJ
TANZANIA, UNITED REPUBLIC OF;TZ
THAILAND;TH
TIMOR-LESTE;TL
TOGO;TG
TOKELAU;TK
TONGA;TO
TRINIDAD AND TOBAGO;TT
TUNISIA;TN
TURKEY;TR
TURKMENISTAN;TM
TURKS AND CAICOS ISLANDS;TC
TUVALU;TV
UGANDA;UG
UKRAINE;UA
UNITED ARAB EMIRATES;AE
UNITED KINGDOM;GB
UNITED STATES;US
UNITED STATES MINOR OUTLYING ISLANDS;UM
URUGUAY;UY
UZBEKISTAN;UZ
VANUATU;VU
VENEZUELA;VE
VIET NAM;VN
VIRGIN ISLANDS, BRITISH;VG
VIRGIN ISLANDS, U.S.;VI
WALLIS AND FUTUNA;WF
WESTERN SAHARA;EH
YEMEN;YE
ZAMBIA;ZM
ZIMBABWE;ZW
