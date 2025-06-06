enum StoryStatusEnum {
  newStory,
  voting,
  voted
}

enum VoteEnum {
  zero(0),
  half(0.5),
  one(1),
  two(2),
  three(3),
  five(5),
  eight(8),
  thirteen(13),
  twenty(20),
  forty(40),
  oneHundred(100),
  questionMark,
  infinity,
  coffee;

  const VoteEnum([this.value]);

  final double? value;
}
