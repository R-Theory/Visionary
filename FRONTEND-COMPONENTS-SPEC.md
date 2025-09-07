# Frontend Component Specifications - Built for Existing APIs

## 🎯 **Component Architecture Strategy**

**Design Principle:** Build UI components that perfectly match existing prototype APIs without requiring backend changes.

**Technology Stack:**
- **Framework:** Svelte 4.2.18 (existing in prototype)
- **PDF Engine:** pdfjs-dist 5.3.93 (existing in prototype) 
- **Styling:** Tailwind 4.0 (existing in prototype)
- **State:** Svelte stores + existing API patterns
- **Build:** Vite 5.4.14 (existing in prototype)

---

## 📁 **Component Hierarchy**

```
src/lib/components/media/
├── MediaLibrary/
│   ├── MediaLibrary.svelte (Main container)
│   ├── MediaGrid.svelte (File grid view)
│   ├── MediaCard.svelte (Individual file card)
│   ├── MediaUpload.svelte (Upload interface)
│   └── MediaSearch.svelte (Search and filters)
├── PDFViewer/
│   ├── PDFViewer.svelte (Main PDF component)
│   ├── PDFPage.svelte (Individual page renderer)
│   ├── PDFNavigation.svelte (Page controls)
│   ├── PDFToolbar.svelte (Zoom, fit controls)
│   └── TTSButton.svelte (Per-page Listen button)
├── TTSInterface/
│   ├── TTSJobManager.svelte (Job status tracking)
│   ├── TTSAudioPlayer.svelte (Audio playback)
│   ├── TTSProgress.svelte (Job progress indicator)
│   └── TTSQueue.svelte (Queue management)
├── VideoPlayer/
│   ├── VideoPlayer.svelte (Video playback)
│   └── VideoControls.svelte (Custom controls)
└── Collections/
    ├── CollectionManager.svelte (Collection CRUD)
    ├── CollectionView.svelte (Collection display)
    └── CollectionSelector.svelte (File organization)
```

---

## 🔗 **API Integration Mapping**

### **Media Library API Consumption**

```typescript
// API endpoints available from prototype
const API_ENDPOINTS = {
  upload: 'POST /api/media/upload',
  list: 'GET /api/media',
  get: 'GET /api/media/{file_id}',
  delete: 'DELETE /api/media/{file_id}',
  content: 'GET /api/media/{file_id}/content',
  extractText: 'POST /api/media/{file_id}/extract-text'
};

// TTS API endpoints
const TTS_ENDPOINTS = {
  createJob: 'POST /api/tts/generate',
  getJob: 'GET /api/tts/job/{job_id}',
  getAudio: 'GET /api/tts/audio/{file_id}/{page}',
  cancelJob: 'DELETE /api/tts/job/{job_id}'
};

// Collection API endpoints
const COLLECTION_ENDPOINTS = {
  create: 'POST /api/collections',
  list: 'GET /api/collections',
  update: 'PUT /api/collections/{id}',
  delete: 'DELETE /api/collections/{id}'
};
```

---

## 📱 **Component Specifications**

### **1. MediaLibrary.svelte** - Main Container
**Purpose:** Top-level component orchestrating all media functionality
**API Integration:** Consumes all media endpoints

```typescript
<script lang="ts">
  import { onMount } from 'svelte';
  import { mediaStore } from '$lib/stores/media';
  import { authStore } from '$lib/stores/auth';
  
  export let view: 'grid' | 'list' = 'grid';
  export let selectedCollection: string | null = null;
  
  // Component state
  let loading = false;
  let error: string | null = null;
  let searchQuery = '';
  let sortBy = 'created_at';
  
  onMount(async () => {
    await loadMediaFiles();
  });
  
  async function loadMediaFiles() {
    loading = true;
    try {
      const response = await fetch('/api/media', {
        headers: { 
          'Authorization': `Bearer ${$authStore.token}`,
          'Content-Type': 'application/json'
        }
      });
      
      if (!response.ok) throw new Error('Failed to load media');
      
      const data = await response.json();
      mediaStore.set(data.media_files);
    } catch (err) {
      error = err.message;
    } finally {
      loading = false;
    }
  }
</script>

<!-- UI Template matching existing API response structure -->
<div class="media-library">
  <MediaUpload on:uploaded={handleFileUploaded} />
  <MediaSearch bind:query={searchQuery} {sortBy} on:filter={handleFilter} />
  
  {#if loading}
    <div class="loading-spinner">Loading media files...</div>
  {:else if error}
    <div class="error-message">{error}</div>
  {:else}
    <MediaGrid 
      files={$mediaStore.filteredFiles} 
      on:select={handleFileSelect}
      on:delete={handleFileDelete}
    />
  {/if}
</div>
```

### **2. PDFViewer.svelte** - Core PDF Component  
**Purpose:** PDF viewing with TTS integration using existing pdfjs-dist
**API Integration:** Uses /api/media/{file_id}/content for PDF data

```typescript
<script lang="ts">
  import { onMount, onDestroy } from 'svelte';
  import * as pdfjsLib from 'pdfjs-dist';
  import { PDFWorker } from 'pdfjs-dist/build/pdf.worker.js';
  
  export let fileId: string;
  export let fileName: string;
  
  // PDF.js configuration (using existing prototype version)
  pdfjsLib.GlobalWorkerOptions.workerSrc = PDFWorker;
  
  // Component state
  let pdfDocument: any = null;
  let currentPage = 1;
  let totalPages = 0;
  let scale = 1.0;
  let loading = true;
  let error: string | null = null;
  
  // Canvas management for page rendering
  let canvasContainer: HTMLDivElement;
  let pageCache = new Map();
  
  onMount(async () => {
    await loadPDF();
  });
  
  async function loadPDF() {
    try {
      loading = true;
      
      // Use existing API endpoint for PDF content
      const response = await fetch(`/api/media/${fileId}/content`, {
        headers: { 'Authorization': `Bearer ${$authStore.token}` }
      });
      
      if (!response.ok) throw new Error('Failed to load PDF');
      
      const pdfData = await response.arrayBuffer();
      pdfDocument = await pdfjsLib.getDocument({ data: pdfData }).promise;
      totalPages = pdfDocument.numPages;
      
      await renderPage(currentPage);
    } catch (err) {
      error = err.message;
    } finally {
      loading = false;
    }
  }
  
  async function renderPage(pageNum: number) {
    if (!pdfDocument) return;
    
    const page = await pdfDocument.getPage(pageNum);
    const viewport = page.getViewport({ scale });
    
    // Create canvas for page rendering
    const canvas = document.createElement('canvas');
    const context = canvas.getContext('2d');
    canvas.height = viewport.height;
    canvas.width = viewport.width;
    
    await page.render({ canvasContext: context, viewport }).promise;
    
    // Update display
    canvasContainer.innerHTML = '';
    canvasContainer.appendChild(canvas);
  }
  
  async function extractPageText(pageNum: number): Promise<string> {
    // Use existing API endpoint for text extraction
    const response = await fetch(`/api/media/${fileId}/extract-text`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${$authStore.token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ page: pageNum })
    });
    
    if (!response.ok) throw new Error('Failed to extract text');
    return await response.text();
  }
</script>

<div class="pdf-viewer">
  <PDFToolbar 
    {currentPage} 
    {totalPages} 
    {scale}
    on:pageChange={handlePageChange}
    on:scaleChange={handleScaleChange}
  />
  
  <div class="pdf-content">
    {#if loading}
      <div class="loading">Loading PDF...</div>
    {:else if error}
      <div class="error">{error}</div>
    {:else}
      <div bind:this={canvasContainer} class="pdf-page-container"></div>
      <TTSButton 
        {fileId} 
        pageNumber={currentPage}
        on:textExtracted={extractPageText}
      />
    {/if}
  </div>
  
  <PDFNavigation 
    {currentPage} 
    {totalPages}
    on:navigate={handleNavigation}
  />
</div>
```

### **3. TTSButton.svelte** - TTS Integration Component
**Purpose:** Per-page TTS job creation and audio playback
**API Integration:** Uses /api/tts/* endpoints from prototype

```typescript
<script lang="ts">
  import { createEventDispatcher } from 'svelte';
  import { ttsStore } from '$lib/stores/tts';
  
  export let fileId: string;
  export let pageNumber: number;
  
  const dispatch = createEventDispatcher();
  
  // Component state
  let jobId: string | null = null;
  let jobStatus: 'idle' | 'creating' | 'queued' | 'processing' | 'completed' | 'failed' = 'idle';
  let audioUrl: string | null = null;
  let error: string | null = null;
  
  // Audio playback state
  let audioElement: HTMLAudioElement;
  let isPlaying = false;
  let currentTime = 0;
  let duration = 0;
  
  async function handleListenClick() {
    if (jobStatus === 'completed' && audioUrl) {
      // Play existing audio
      togglePlayback();
      return;
    }
    
    // Create new TTS job using existing API
    await createTTSJob();
  }
  
  async function createTTSJob() {
    try {
      jobStatus = 'creating';
      error = null;
      
      // Extract text for current page (dispatched to parent)
      const pageText = await dispatch('textExtracted', pageNumber);
      
      // Use existing TTS API endpoint
      const response = await fetch('/api/tts/generate', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${$authStore.token}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          media_file_id: fileId,
          page_number: pageNumber,
          text_content: pageText,
          voice: 'alloy' // Default voice
        })
      });
      
      if (!response.ok) throw new Error('Failed to create TTS job');
      
      const jobData = await response.json();
      jobId = jobData.id;
      jobStatus = 'queued';
      
      // Start polling for job completion
      pollJobStatus();
    } catch (err) {
      error = err.message;
      jobStatus = 'failed';
    }
  }
  
  async function pollJobStatus() {
    if (!jobId) return;
    
    try {
      const response = await fetch(`/api/tts/job/${jobId}`, {
        headers: { 'Authorization': `Bearer ${$authStore.token}` }
      });
      
      if (!response.ok) throw new Error('Failed to get job status');
      
      const jobData = await response.json();
      jobStatus = jobData.status;
      
      if (jobStatus === 'completed') {
        audioUrl = jobData.audio_url;
      } else if (jobStatus === 'failed') {
        error = jobData.error_message;
      } else if (jobStatus === 'processing' || jobStatus === 'queued') {
        // Continue polling
        setTimeout(pollJobStatus, 2000);
      }
    } catch (err) {
      error = err.message;
      jobStatus = 'failed';
    }
  }
  
  function togglePlayback() {
    if (!audioElement || !audioUrl) return;
    
    if (isPlaying) {
      audioElement.pause();
    } else {
      audioElement.play();
    }
  }
</script>

<div class="tts-button-container">
  <button 
    class="tts-button"
    class:loading={jobStatus === 'creating' || jobStatus === 'queued' || jobStatus === 'processing'}
    class:completed={jobStatus === 'completed'}
    class:failed={jobStatus === 'failed'}
    on:click={handleListenClick}
    disabled={jobStatus === 'creating' || jobStatus === 'processing'}
  >
    {#if jobStatus === 'idle'}
      🔊 Listen
    {:else if jobStatus === 'creating' || jobStatus === 'queued'}
      ⏳ Queued
    {:else if jobStatus === 'processing'}
      🔄 Processing
    {:else if jobStatus === 'completed'}
      {isPlaying ? '⏸️ Pause' : '▶️ Play'}
    {:else if jobStatus === 'failed'}
      ❌ Failed
    {/if}
  </button>
  
  {#if error}
    <div class="error-message">{error}</div>
  {/if}
  
  {#if audioUrl}
    <audio 
      bind:this={audioElement}
      src={audioUrl}
      bind:currentTime
      bind:duration
      on:play={() => isPlaying = true}
      on:pause={() => isPlaying = false}
      on:ended={() => isPlaying = false}
    ></audio>
    
    {#if jobStatus === 'completed'}
      <div class="audio-progress">
        <div class="progress-bar" style="width: {(currentTime / duration) * 100}%"></div>
      </div>
    {/if}
  {/if}
</div>
```

### **4. MediaUpload.svelte** - File Upload Component
**Purpose:** Drag-and-drop file upload with progress tracking
**API Integration:** Uses /api/media/upload endpoint from prototype

```typescript
<script lang="ts">
  import { createEventDispatcher } from 'svelte';
  
  const dispatch = createEventDispatcher();
  
  // Component state
  let dragOver = false;
  let uploading = false;
  let uploadProgress = 0;
  let error: string | null = null;
  
  // File validation (matches prototype constraints)
  const MAX_FILE_SIZE = 100 * 1024 * 1024; // 100MB from prototype
  const ALLOWED_TYPES = ['pdf', 'mp4', 'avi', 'mov', 'mp3', 'wav'];
  
  function handleDragOver(event: DragEvent) {
    event.preventDefault();
    dragOver = true;
  }
  
  function handleDragLeave() {
    dragOver = false;
  }
  
  async function handleDrop(event: DragEvent) {
    event.preventDefault();
    dragOver = false;
    
    const files = Array.from(event.dataTransfer?.files || []);
    for (const file of files) {
      await uploadFile(file);
    }
  }
  
  async function handleFileSelect(event: Event) {
    const input = event.target as HTMLInputElement;
    const files = Array.from(input.files || []);
    
    for (const file of files) {
      await uploadFile(file);
    }
  }
  
  function validateFile(file: File): boolean {
    // Size validation
    if (file.size > MAX_FILE_SIZE) {
      error = `File size exceeds 100MB limit`;
      return false;
    }
    
    // Type validation (basic check, backend does full validation)
    const extension = file.name.split('.').pop()?.toLowerCase();
    if (!extension || !ALLOWED_TYPES.includes(extension)) {
      error = `File type not supported. Allowed: ${ALLOWED_TYPES.join(', ')}`;
      return false;
    }
    
    return true;
  }
  
  async function uploadFile(file: File) {
    if (!validateFile(file)) return;
    
    try {
      uploading = true;
      uploadProgress = 0;
      error = null;
      
      const formData = new FormData();
      formData.append('file', file);
      
      // Use existing upload endpoint from prototype
      const response = await fetch('/api/media/upload', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${$authStore.token}`
        },
        body: formData
      });
      
      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.detail || 'Upload failed');
      }
      
      const uploadedFile = await response.json();
      dispatch('uploaded', uploadedFile);
      
    } catch (err) {
      error = err.message;
    } finally {
      uploading = false;
      uploadProgress = 0;
    }
  }
</script>

<div 
  class="upload-area"
  class:drag-over={dragOver}
  class:uploading={uploading}
  on:dragover={handleDragOver}
  on:dragleave={handleDragLeave}
  on:drop={handleDrop}
>
  {#if uploading}
    <div class="upload-progress">
      <div class="progress-text">Uploading... {uploadProgress}%</div>
      <div class="progress-bar">
        <div class="progress-fill" style="width: {uploadProgress}%"></div>
      </div>
    </div>
  {:else}
    <div class="upload-content">
      <div class="upload-icon">📁</div>
      <p>Drag and drop files here, or</p>
      <label class="file-select-button">
        Choose Files
        <input 
          type="file" 
          multiple 
          accept=".pdf,.mp4,.avi,.mov,.mp3,.wav"
          on:change={handleFileSelect}
          hidden
        />
      </label>
      <p class="file-constraints">
        Supported: PDF, MP4, AVI, MOV, MP3, WAV<br/>
        Maximum size: 100MB per file
      </p>
    </div>
  {/if}
  
  {#if error}
    <div class="error-message">{error}</div>
  {/if}
</div>
```

---

## 🎨 **Styling & Theme Integration**

### **Tailwind Configuration**
Using existing Tailwind 4.0 from prototype with OpenWebUI-compatible classes:

```css
/* Media Library Styling */
.media-library {
  @apply container mx-auto px-4 py-6;
}

.media-grid {
  @apply grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4;
}

.media-card {
  @apply bg-white dark:bg-gray-800 rounded-lg shadow-md hover:shadow-lg transition-shadow;
  @apply border border-gray-200 dark:border-gray-700;
}

/* PDF Viewer Styling */
.pdf-viewer {
  @apply flex flex-col h-full bg-gray-50 dark:bg-gray-900;
}

.pdf-content {
  @apply flex-1 overflow-auto p-4;
}

.pdf-page-container {
  @apply flex justify-center;
}

/* TTS Button Styling */
.tts-button {
  @apply px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700;
  @apply disabled:opacity-50 disabled:cursor-not-allowed;
  @apply transition-colors duration-200;
}

.tts-button.loading {
  @apply bg-yellow-500 hover:bg-yellow-600;
}

.tts-button.completed {
  @apply bg-green-600 hover:bg-green-700;
}

.tts-button.failed {
  @apply bg-red-600 hover:bg-red-700;
}

/* Upload Area Styling */
.upload-area {
  @apply border-2 border-dashed border-gray-300 dark:border-gray-600;
  @apply rounded-lg p-8 text-center transition-colors;
}

.upload-area.drag-over {
  @apply border-blue-500 bg-blue-50 dark:bg-blue-900/20;
}
```

---

## 📦 **Component Integration Strategy**

### **Store Management**
```typescript
// src/lib/stores/media.ts
import { writable } from 'svelte/store';

export interface MediaFile {
  id: string;
  user_id: string;
  original_filename: string;
  file_type: string;
  file_size: number;
  storage_path: string;
  metadata: any;
  created_at: number;
  updated_at: number;
}

export const mediaStore = writable<MediaFile[]>([]);
export const selectedFileStore = writable<MediaFile | null>(null);
export const uploadProgressStore = writable<number>(0);
```

### **API Service Layer**
```typescript
// src/lib/services/mediaApi.ts
import type { MediaFile } from '../stores/media';

export class MediaApiService {
  constructor(private baseUrl: string = '/api') {}
  
  async uploadFile(file: File): Promise<MediaFile> {
    // Matches existing prototype endpoint exactly
  }
  
  async getMediaFiles(): Promise<MediaFile[]> {
    // Uses existing /api/media endpoint
  }
  
  async deleteFile(fileId: string): Promise<void> {
    // Uses existing DELETE endpoint
  }
  
  // ... other methods matching prototype API
}
```

**Result:** Complete frontend specification that maximizes prototype backend value without requiring any API changes.