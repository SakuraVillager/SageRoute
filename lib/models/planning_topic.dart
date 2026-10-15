import 'topic_record.dart';

const dongpoRouteName = '东坡杭州行迹';
const dongpoRouteId = -10001;
const dongpoPlanningTopic = TopicRecord(
  id: dongpoRouteId,
  createdAt: null,
  celebrity: '苏轼',
  name: dongpoRouteName,
  description: '37 处杭州行迹，沿着治水、交游与诗文认识东坡。',
);

bool isDongpoFigure(String? name) =>
    const ['苏轼', '苏东坡', '东坡'].contains(name?.trim());

bool isDongpoRouteName(String name) =>
    const ['东坡杭州行迹', '苏轼·杭州行迹', '苏轼杭州行迹'].contains(name);
