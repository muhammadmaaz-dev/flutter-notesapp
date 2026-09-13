import 'package:appwrite/appwrite.dart';
import 'package:newapp/services/appwrite_service.dart';

final Client client = Client()
    .setProject(AppwriteConfig.projectId)
    .setEndpoint(AppwriteConfig.endpoint);
