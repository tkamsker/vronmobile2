# VRON Mobile App - Product Requirements Document (PRD)

## 1. Introduction

This document outlines the product requirements for the VRON mobile application for iOS. The application will be developed using Flutter and will leverage the existing backend infrastructure of the VRON React web application. The primary goal is to provide a native mobile experience for VRON users, with a special focus on integrating on-device LiDAR scanning capabilities for room and space capture.

**Key Technologies:**
- **Framework:** Flutter
- **Backend Communication:** GraphQL (Primary), REST for file uploads if necessary.
- **Authentication:** JWT-based, with support for OAuth (Google, Facebook).
- **3D & Scanning:** `flutter_roomplan` for LiDAR capture, and other libraries for GLB conversion and viewing.

## 2. General Requirements

### Loading Screen
- **Figma:** [Loading Screen Design](https://www.figma.com/design/yLDwcYYxrZKf2u59TO8FjO/vron?node-id=1-2&t=1HsKPOtiHhz8STE2-4)
- **Description:** Upon app launch, a loading screen with the VRON logo and a subtle animation will be displayed while initial resources, configurations, and session data are loaded.

### Backend Configuration
- **Description:** The app must be configurable to connect to different backend environments (development, staging, production).
- **Technical Requirements:**
    - The application will fetch its configuration from an environment file.
    - **`GRAPHQL_ENDPOINT`**: `https://api.vron.stage.motorenflug.at/graphql`
    - **`GRAPHQL_WS_ENDPOINT`**: `wss://api.vron.stage.motorenflug.at/graphql`
    - These values will be used to configure the Apollo GraphQL client for Flutter.

## 3. Use Cases (UC)

### UC1: Main Screen (Not Logged-In)
- **Figma:** [Main Screen Layout](https://www.figma.com/design/yLDwcYYxrZKf2u59TO8FjO/vron?node-id=1-34&t=1HsKPOtiHhz8STE2-4)
- **Description:** Users who open the app without an active session will be presented with a main screen that provides options to sign in, create an account, or use the app in guest mode.
- **Features:**
    - Email and Password input fields.
    - "Sign In" button.
    - "Sign in with Google" button.
    - "Sign in with Facebook" button.
    - "Forgot Password?" link.
    - "Create Account" link.
    - "Guest Mode" button.

### UC2: Email & Password Authentication
- **Description:** Users can log in using their registered email and password.
- **Technical Requirements:**
    - The app will use the `login` GraphQL mutation.
    - **Mutation:**
      ```graphql
      mutation login($email: String!, $password: String!) {
        login(data: { email: $email, password: $password }) {
          token
          user {
            id
            email
            firstName
            lastName
          }
        }
      }
      ```
    - Upon successful login, the returned JWT `token` will be securely stored on the device (e.g., using `flutter_secure_storage`) and used in the `Authorization` header for all subsequent authenticated API calls.

### UC3: Google Login
- **Description:** Users can sign in using their Google account.
- **Technical Requirements:**
    - The app will use a Flutter library like `google_sign_in` to initiate the Google OAuth flow on the device.
    - This flow will provide an `accessToken`.
    - The `accessToken` will be sent to the backend using the `loginWithProvider` GraphQL mutation.
    - **Mutation:**
      ```graphql
      mutation loginWithProvider($provider: String!, $accessToken: String!) {
        loginWithProvider(data: { provider: $provider, accessToken: $accessToken }) {
          token
          user {
            id
            # ... other user fields
          }
        }
      }
      ```
    - The `provider` variable will be the string `"google"`.
    - The returned JWT `token` will be stored and used for the session.

### UC4: Facebook Login
- **Description:** Users can sign in using their Facebook account.
- **Technical Requirements:**
    - The app will use a Flutter library like `flutter_facebook_auth` to initiate the Facebook OAuth flow.
    - This flow will provide an `accessToken`.
    - The `accessToken` will be sent to the backend using the same `loginWithProvider` GraphQL mutation as Google Login.
    - The `provider` variable will be the string `"facebook"`.
    - The returned JWT `token` will be stored and used for the session.

### UC5: Forgot Password
- **Description:** If a user forgets their password, they can initiate a recovery process.
- **Technical Requirements:**
    - Tapping the "Forgot Password" link will open a web browser (e.g., using `url_launcher`) to the password reset page on the main `vron.one` website.
    - The specific URL should be configurable and likely corresponds to the `forgot-password` route in the web app. The mobile app itself will not contain the password reset forms.

### UC6: Create Account
- **Description:** New users can create a VRON account.
- **Technical Requirements:**
    - The app will provide a form for `firstName`, `lastName`, `email`, and `password`.
    - Upon submission, the app will call the `register` GraphQL mutation.
    - **Mutation:**
      ```graphql
      mutation register($firstName: String!, $lastName: String!, $email: String!, $password: String!) {
        register(data: { firstName: $firstName, lastName: $lastName, email: $email, password: $password }) {
          # ... response fields, typically confirmation message
        }
      }
      ```

### UC7: Guest Mode
- **Description:** Guest mode allows users to access the LiDAR scanning functionality without logging in.
- **Technical Requirements:**
    - Tapping the "Guest Mode" button will navigate the user directly to the "Start Scanning" screen (UC14).
    - In guest mode, there is no backend access. All scanned data is stored locally on the device.
    - The option to "Save to Project" (UC20) will be disabled or hidden. The user can only export the scan as a GLB file to their local device storage.

### UC8: View Projects
- **Figma:** [Projects List](https://www.figma.com/design/yLDwcYYxrZKf2u59TO8FjO/vron?node-id=1-129&t=1HsKPOtiHhz8STE2-4)
- **Description:** After a successful login, the user is presented with a list of their projects.
- **Technical Requirements:**
    - The app will call a `projects` GraphQL query to fetch the list of projects for the logged-in user.
    - The query should support pagination.
    - The media/images for each project (e.g., thumbnails) are returned as URLs within the project data. The app will use a standard image loading library (like `cached_network_image`) to display them.
    - **Query (Example):**
      ```graphql
      query projects($limit: Int, $offset: Int) {
        projects(limit: $limit, offset: $offset) {
          id
          name
          description
          thumbnailUrl # Or similar field for project image
          # ... other project fields
        }
      }
      ```

### UC9: Search Projects
- **Description:** Users can search for projects by name.
- **Technical Requirements:**
    - The `projects` GraphQL query will be updated to include a search parameter.
    - **Query (Example):**
      ```graphql
      query projects($search: String, $limit: Int, $offset: Int) {
        projects(search: $search, limit: $limit, offset:offset) {
          # ... project fields
        }
      }
      ```
    - A search bar in the UI will trigger this query as the user types (with debouncing).

### UC10: Project Detail
- **Figma:** [Project Detail Screen](https://www.figma.com/design/yLDwcYYxrZKf2u59TO8FjO/vron?node-id=1-317&t=1HsKPOtiHhz8STE2-4)
- **Description:** Tapping the "Enter project" button on a project card navigates to the project's detail screen.
- **Technical Requirements:**
    - This screen displays high-level information about the project.
    - It uses a `project` GraphQL query, passing the project's ID.
    - **Query (Example):**
      ```graphql
      query project($id: ID!) {
        project(id: $id) {
          id
          name
          description
          # ... other detailed fields
        }
      }
      ```

### UC11: Project Data
- **Figma:** [Project Data Screen](https://www.figma.com/design/yLDwcYYxrZKf2u59TO8FjO/vron?node-id=16-1916&t=1HsKPOtiHhz8STE2-4)
- **Description:** From the project detail screen, pressing "Project data" shows more specific, editable data about the project.
- **Technical Requirements:**
    - This view likely reuses the data from the `project` query (UC10) and presents it in an editable form.
    - Saving changes would involve a corresponding `updateProject` mutation.

### UC12: View Products
- **Figma:** [Product List (Grid)](https://www.figma.com/design/yLDwcYYxrZKf2u59TO8FjO/vron?node-id=80-1313&t=1HsKPOtiHhz8STE2-4), [Product List (List)](https://www.figma.com/design/yLDwcYYxrZKf2u59TO8FjO/vron?node-id=79-378&t=1HsKPOtiHhz8STE2-4)
- **Description:** From the project detail screen, pressing "Products" shows a list of products associated with that merchant/project.
- **Technical Requirements:**
    - The app will call a `products` or `shopProducts` GraphQL query, likely passing a `shopId` or `merchantId` associated with the current project.
    - **Query (Example from `graphql/shop/queries.graphql`):**
      ```graphql
      query productsByShop($shopId: ID!, $limit: Int, $offset: Int) {
        products(shopId: $shopId, limit: $limit, offset: $offset) {
          id
          name
          description
          price
          images {
            url
          }
          # ... other product fields
        }
      }
      ```

### UC13: Create Product
- **Figma:** [Create Product Form](https://www.figma.com/design/yLDwcYYxrZKf2u59TO8FjO/vron?node-id=79-475&t=1HsKPOtiHhz8STE2-4)
- **Description:** Users can add a new product to their shop.
- **Technical Requirements:**
    - The "Create Product" button opens a form with fields for product name, description, price, categories, images, etc.
    - The fields and their validation will be based on the Zod schema found in `components/product/schema.ts` in the web app.
    - Submitting the form will call the `createProduct` GraphQL mutation.
    - Image uploads will be handled via a multipart request to a specific upload endpoint, which returns a file ID or URL to be used in the mutation.
    - **Mutation (Example from `graphql/shop/mutations.graphql`):**
      ```graphql
      mutation createProduct($input: CreateProductInput!) {
        createProduct(data: $input) {
          id
          name
        }
      }
      ```

### UC14: LiDAR Scanning
- **Figma:** [Start Scanning Screen](https://www.figma.com/design/yLDwcYYxrZKf2u59TO8FjO/vron?node-id=1-521&t=1HsKPOtiHhz8STE2-4)
- **Description:** Provides the core functionality of scanning a room using the device's LiDAR sensor.
- **Technical Requirements:**
    - **Capability Check:** The app must first check if the device has a LiDAR sensor and is running a compatible iOS version. The "Start Scanning" button should be disabled if not capable.
    - **Permissions:** The app must request camera and sensor permissions before starting a scan.
    - **Implementation:** The scanning functionality will be implemented using the `flutter_roomplan` package ([https://github.com/Barba2k2/flutter_roomplan](https://github.com/Barba2k2/flutter_roomplan)).
    - **Data Storage:** The raw scan data from `flutter_roomplan` will be stored locally in a temporary directory on the device.
    - **GLB Upload:** For logged-in users, the screen should allow uploading a pre-existing `.glb` file. This will use a file picker and an `uploadWorld` or similar GraphQL mutation. This is also available for guests, but they can only export the file locally.

### UC15: Post-Scan Preview
- **Figma:** [Scan Preview Form](https://www.figma.com/design/yLDwcYYxrZKf2u59TO8FjO/vron?node-id=133-3&t=1HsKPOtiHhz8STE2-4)
- **Description:** After a scan is completed, the user is shown a preview of the captured 3D model.
- **Technical Requirements:**
    - The captured data (likely a 3D model file) will be rendered in a 3D view within the app (e.g., using a package like `model_viewer_plus`).
    - The user can pan, zoom, and rotate the model to inspect it.
    - A "Save Scan" button proceeds to the next step.

### UC16: Multi-Room Options
- **Figma:** [Multi-Room Form](https://www.figma.com/design/yLDwcYYxrZKf2u59TO8FjO/vron?node-id=140-599&t=1HsKPOtiHhz8STE2-4)
- **Description:** After saving a scan, the user is given the option to scan another room or proceed with the current scan.
- **Technical Requirements:**
    - "Scan another room" navigates back to the scanning screen (UC14) to capture another room as part of the same session.
    - Other buttons navigate to the stitching or export process.

### UC17: Room Stitching & Editing
- **Figma:** [Stitching UI](https://www.figma.com/design/yLDwcYYxrZKf2u59TO8FjO/vron?node-id=133-70&t=1HsKPOtiHhz8STE2-4)
- **Description:** A 2D top-down editor where users can assemble and adjust multiple scanned rooms.
- **Technical Requirements:**
    - Each scanned room is represented by its floor plan outline.
    - Users can drag to move and rotate each room's outline.
    - An "Add Door" tool allows the user to draw a line on the edge of a room's outline to signify a doorway, which is used to logically connect rooms.

### UC18: Export Session to GLB
- **Figma:** [Export Layout](https://www.figma.com/design/yLDwcYYxrZKf2u59TO8FjO/vron?node-id=156-467&t=1HsKPOtiHhz8STE2-4)
- **Description:** The final stitched layout is converted into a single `.glb` 3D model file.
- **Technical Requirements:**
    - The app will use a client-side library or a bundled native library to process the locally stored scan files and the stitching data (room positions, door locations).
    - This process will generate a single `.glb` file representing the entire scanned space.
    - The generated file is stored locally, ready for preview or upload.

### UC19: Preview GLB
- **Figma:** [GLB Preview](https://www.figma.com/design/yLDwcYYxrZKf2u59TO8FjO/vron?node-id=156-1360&t=1HsKPOtiHhz8STE2-4)
- **Description:** Allows the user to view the final, exported GLB file before saving it to a project.
- **Technical Requirements:**
    - This screen uses the same 3D viewer component from UC15 to render the final `.glb` model.

### UC20: Generate NavMesh & Save to Project
- **Figma:** [Generate NavMesh Form](https://www.figma.com/design/yLDwcYYxrZKf2u59TO8FjO/vron?node-id=156-1543&t=1HsKPOtiHhz8STE2-4), [Save to Project Form](https://www.figma.com/design/yLDwcYYxrZKf2u59TO8FjO/vron?node-id=156-2057&t=1HsKPOtiHhz8STE2-4)
- **Description:** The user can generate a navigation mesh for the model and save all assets to a project.
- **Technical Requirements:**
    - **NavMesh Generation:** This may require an external service or a complex client-side library. The app will upload the `.glb` model and receive a navmesh file (also likely `.glb`) in return.
    - **Save to Project:**
        - This form allows the user to select which assets to save (e.g., raw scan, final GLB, NavMesh GLB).
        - The app will use a GraphQL mutation like `updateProjectWorlds` or `uploadWorldAssets` to upload the selected files and associate them with the chosen project. The upload mechanism will be a standard multipart POST request.

### UC21: Settings
- **Figma:** [Settings Page](https://www.figma.com/design/yLDwcYYxrZKf2u59TO8FjO/vron?node-id=1-1000&t=1HsKPOtiHhz8STE2-4)
- **Description:** A screen for managing app and user settings.
- **Features:**
    - Edit Profile
    - Change Password
    - Language Selection
    - Logout

### UC22: Language Selection
- **Figma:** [Language Page](https://www.figma.com/design/yLDwcYYxrZKf2u59TO8FjO/vron?node-id=1-1157&t=1HsKPOtiHhz8STE2-4)
- **Description:** Allows the user to change the display language of the app.
- **Technical Requirements:**
    - The app will use Flutter's internationalization (i18n) capabilities.
    - Language files (`.arb` or similar) will contain translations for all UI strings.
    - The available languages will be German (de), English (en), and Portuguese (pt), matching the web app.
    - The selected language will be persisted on the device.
