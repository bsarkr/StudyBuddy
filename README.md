# StudyBuddy

By Bilash Sarkar and Max Hazelton

StudyBuddy is a full-stack iOS study app that helps students create, organize, and share study materials. Designed with both utility and aesthetics in mind, it offers a sleek, social-first interface to support modern learning habits. Users can make flashcard sets, organize them into folders, and connect with friends for collaborative study.

The goal of StudyBuddy is to centralize the studying experience into one clean and customizable platform. Traditional flashcard apps often lack social features or feel too static. StudyBuddy bridges that gap by:
- Letting users organize their material in sets and folders.
- Supporting profile customization, friend requests, and messaging.
- Encouraging active learning with a dedicated “Learn Mode”.
- Making the UI feel as fun and intuitive as modern social apps.

Technologies Used
- SwiftUI – Building a responsive and interactive iOS interface.
- Firebase Authentication – Secure login and sign-up flow.
- Firebase Firestore – Real-time database for users, sets, folders, and friends.
- Firebase Storage – Image hosting for user profile pictures.
- PhotosUI / UIImagePickerController – Profile image selection and cropping.
- Git & GitHub – Version control and collaborative development.


Setup & Installation
1. Clone the repository: git clone https://github.com/your-username/studybuddy.git
2. Open the project in Xcode 15+.
3. Run pod install if necessary for Firebase integration.
4. Connect your own Firebase project by replacing GoogleService-Info.plist.
5. Make sure Firebase Authentication, Firestore, and Storage are all enabled in your Firebase console.
6. Build and run on a real device or simulator.


Contributions & Learnings

This app was built as part of a semester-long project where I developed the full-stack functionality, from UI design to backend setup. Key accomplishments and challenges include:
- Developed user authentication and setup with Firebase and tracking sessions.
- Implemented real-time friend request and messaging systems using Firebase listeners.
- Integrated profile photo uploading with cropping using UIImagePickerController and Firebase Storage.
- Designed a custom bottom tab bar to maintain consistent navigation across views.
- Refactored large-scale SwiftUI files to be modular and scalable.
- Collaborated on GitHub with conflict resolution and codebase merging.



StudyBuddy reflects my passion for frontend design, backend logic, and creating something that’s both functional and delightful to use. It’s taught me the value of clean code, real-time responsiveness, and creating seamless user flows—skills I’m excited to bring into any professional software engineering environment. 
