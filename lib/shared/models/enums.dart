enum StatusEnum { notStarted, started, skipped, ended }

enum VoteEnum {
  zero('0', 0),
  half('½', 0.5),
  one('1', 1),
  two('2', 2),
  three('3', 3),
  five('5', 5),
  eight('8', 8),
  thirteen('13', 13),
  twenty('20', 20),
  forty('40', 40),
  oneHundred('100', 100),
  questionMark('?'),
  infinity('∞'),
  coffee('coffee');

  const VoteEnum(this.label, [this.value]);

  final double? value;
  final String label;
}
