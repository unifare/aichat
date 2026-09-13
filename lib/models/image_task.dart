
enum ImageStatus { queued, generating, completed, failed }
class ImageTask {
  final String id;
  final String prompt;
  final String model;
  final String size;
  final ImageStatus status;
  final List<String> imageUrls;
  final String? error;
  final int progress;
  const ImageTask({required this.id, required this.prompt, required this.model, required this.size, required this.status, this.imageUrls=const [], this.error, this.progress=0});
  ImageTask copyWith({ImageStatus? status, List<String>? imageUrls, String? error, int? progress})=>ImageTask(id:id,prompt:prompt,model:model,size:size,status:status??this.status,imageUrls:imageUrls??this.imageUrls,error:error??this.error,progress:progress??this.progress);
}
