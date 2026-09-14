'use client';

import { FormEvent, useEffect, useState } from 'react';
import { AdminShell } from '@/components/AdminShell';
import { apiFetch } from '@/lib/api';

type Course = { id: string; title: string; isPublished: boolean };
type Lesson = { id: string; title: string; unitId: string };
type Exercise = {
  id: string;
  type: string;
  prompt: string;
  order: number;
};

export default function CmsPage() {
  const [courses, setCourses] = useState<Course[]>([]);
  const [courseId, setCourseId] = useState('');
  const [lessons, setLessons] = useState<Lesson[]>([]);
  const [lessonId, setLessonId] = useState('');
  const [exercises, setExercises] = useState<Exercise[]>([]);
  const [prompt, setPrompt] = useState('');
  const [error, setError] = useState('');

  useEffect(() => {
    apiFetch<Course[]>('/admin/courses')
      .then((c) => {
        setCourses(c);
        if (c[0]) setCourseId(c[0].id);
      })
      .catch((err) =>
        setError(err instanceof Error ? err.message : 'Failed to load'),
      );
  }, []);

  useEffect(() => {
    if (!courseId) return;
    apiFetch<Lesson[]>(`/admin/lessons?courseId=${courseId}`)
      .then((l) => {
        setLessons(l);
        if (l[0]) setLessonId(l[0].id);
      })
      .catch(() => setLessons([]));
  }, [courseId]);

  useEffect(() => {
    if (!lessonId) return;
    apiFetch<Exercise[]>(`/admin/exercises?lessonId=${lessonId}`)
      .then(setExercises)
      .catch(() => setExercises([]));
  }, [lessonId]);

  async function onCreateExercise(e: FormEvent) {
    e.preventDefault();
    if (!lessonId || !prompt.trim()) return;
    await apiFetch('/admin/exercises', {
      method: 'POST',
      body: JSON.stringify({
        lessonId,
        type: 'multiple_choice',
        prompt,
        order: exercises.length + 1,
        content: { stem: prompt, options: ['A', 'B', 'C', 'D'] },
        answer: { correctOption: 'A' },
      }),
    });
    setPrompt('');
    const updated = await apiFetch<Exercise[]>(
      `/admin/exercises?lessonId=${lessonId}`,
    );
    setExercises(updated);
  }

  return (
    <AdminShell>
      <h2>CMS — Courses &amp; Lessons</h2>
      {error && <p className="error">{error}</p>}

      <div className="card">
        <label>Course</label>
        <select
          value={courseId}
          onChange={(e) => setCourseId(e.target.value)}
        >
          {courses.map((c) => (
            <option key={c.id} value={c.id}>
              {c.title} {c.isPublished ? '(published)' : ''}
            </option>
          ))}
        </select>

        <label>Lesson</label>
        <select value={lessonId} onChange={(e) => setLessonId(e.target.value)}>
          {lessons.map((l) => (
            <option key={l.id} value={l.id}>
              {l.title}
            </option>
          ))}
        </select>
      </div>

      <div className="card">
        <h3>Exercises</h3>
        <table>
          <thead>
            <tr>
              <th>Order</th>
              <th>Type</th>
              <th>Prompt</th>
            </tr>
          </thead>
          <tbody>
            {exercises.map((ex) => (
              <tr key={ex.id}>
                <td>{ex.order}</td>
                <td>{ex.type}</td>
                <td>{ex.prompt}</td>
              </tr>
            ))}
          </tbody>
        </table>

        <form onSubmit={onCreateExercise} style={{ marginTop: '1rem' }}>
          <label>New exercise prompt</label>
          <input
            value={prompt}
            onChange={(e) => setPrompt(e.target.value)}
            placeholder="Exercise prompt…"
          />
          <button type="submit">Add MC exercise</button>
        </form>
      </div>
    </AdminShell>
  );
}
