# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.

# Keep MediaPipe classes
-keep class com.google.mediapipe.** { *; }
-keep class com.google.protobuf.** { *; }

# Keep LLM helper classes
-keep class com.example.noodle.LlmHelper { *; }
-keep class com.example.noodle.AppLlmModel { *; }
-keep class com.example.noodle.InitResult { *; }

# Keep method channel classes
-keep class io.flutter.plugin.common.MethodChannel { *; }
-keep class io.flutter.plugin.common.MethodCall { *; }
-keep class io.flutter.plugin.common.MethodResult { *; }

# Keep Flutter engine classes
-keep class io.flutter.embedding.engine.** { *; }
-keep class io.flutter.embedding.android.** { *; }

# Keep annotation processing classes
-keep class javax.annotation.processing.** { *; }
-keep class javax.lang.model.** { *; }
-keep class autovalue.** { *; }

# Keep Play Core classes
-keep class com.google.android.play.core.** { *; }

# Keep MediaPipe proto classes
-keep class com.google.mediapipe.proto.** { *; }

# Keep protobuf internal classes
-keep class com.google.protobuf.Internal.** { *; }
-keep class com.google.protobuf.ProtoField { *; }
-keep class com.google.protobuf.ProtoPresenceBits { *; }
-keep class com.google.protobuf.ProtoPresenceCheckedField { *; }

# Keep javax tools classes
-keep class javax.tools.** { *; }

# Keep XML stream classes
-keep class javax.xml.stream.** { *; }

# Keep protobuf generated classes
-keep class * extends com.google.protobuf.GeneratedMessageLite { *; }
-keep class * extends com.google.protobuf.GeneratedMessage { *; }

# Keep MediaPipe task classes
-keep class com.google.mediapipe.tasks.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep enum values
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep reflection
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes SourceFile,LineNumberTable
-keepattributes Exceptions,InnerClasses

# Keep method names for debugging
-keepattributes LocalVariableTable
-keepattributes LocalVariableTypeTable

# Keep generic signatures
-keepattributes Signature

# Keep source file names for debugging
-keepattributes SourceFile

# Keep line numbers for debugging
-keepattributes LineNumberTable

# Keep exceptions
-keepattributes Exceptions

# Keep inner classes
-keepattributes InnerClasses

# Keep synthetic methods
-keepattributes Synthetic

# Keep bridge methods
-keepattributes Bridge

# Keep varargs
-keepattributes Varargs

# Keep enum constants
-keepattributes EnumConstant

# Keep annotation default values
-keepattributes AnnotationDefault

# Keep method parameters
-keepattributes MethodParameters
