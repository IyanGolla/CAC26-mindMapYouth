/// Hard-coded so the hub never depends on a network fetch.
/// Re-verify every number and hours before each release.
class CrisisLine {
  const CrisisLine({
    required this.name,
    required this.about,
    this.call,
    this.callLabel,
    this.text,
    this.textBody,
  });

  final String name;
  final String about;
  final String? call;
  final String? callLabel;
  final String? text;
  final String? textBody;
}

const lifeline988 = CrisisLine(
  name: '988 Suicide & Crisis Lifeline',
  about: 'Free, 24/7. Talk or text with a trained counselor about anything.',
  call: '988',
  text: '988',
);

const otherCrisisLines = [
  CrisisLine(
    name: 'Crisis Text Line',
    about: 'Text with a trained volunteer. No talking out loud.',
    text: '741741',
    textBody: 'HOME',
  ),
  CrisisLine(
    name: 'Teen Link',
    about: 'Washington teens trained to listen to teens. Evenings.',
    call: '866-833-6546',
    callLabel: '866-TEENLINK',
  ),
  CrisisLine(
    name: 'The Trevor Project',
    about: 'For LGBTQ+ young people, 24/7.',
    call: '866-488-7386',
    text: '678678',
    textBody: 'START',
  ),
  CrisisLine(
    name: 'Trans Lifeline',
    about: 'Peer support run by and for trans people.',
    call: '877-565-8860',
  ),
  CrisisLine(
    name: 'WA Recovery Help Line',
    about: 'Substance use and mental health help, 24/7.',
    call: '866-789-1511',
  ),
];
