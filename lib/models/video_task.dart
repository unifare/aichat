
enum VideoStatus { queued, processing, completed, failed }
class VideoTask {
  final String id;
  final String prompt;
  final String model;
  final String duration;
  final VideoStatus status;
  final int progress;
  final String? videoUrl;
  final String? error;
  const VideoTask({required this.id, required this.prompt, required this.model, required this.duration, required this.status, this.progress=0, this.videoUrl, this.error});
  VideoTask copyWith({VideoStatus? status, int? progress, String? videoUrl, String? error})=>VideoTask(id:id,prompt:prompt,model:model,duration:duration,status:status??this.status,progress:progress??this.progress,videoUrl:videoUrl??this.videoUrl,error:error??this.error);
}
