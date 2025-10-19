# Supabaseセットアップ手順

このファイルでは、手動で行う必要がある初期設定を説明します。

## 1. Supabaseプロジェクト作成（手動）

### 1-1. アカウント作成・プロジェクト作成
1. https://supabase.com にアクセス
2. "Start your project" をクリック
3. GitHubアカウントでサインアップ
4. "New Project" をクリック
5. 以下を入力：
   - **Name**: `srt-app`（任意）
   - **Database Password**: 強力なパスワードを生成（メモしておく）
   - **Region**: `Northeast Asia (Tokyo)` を選択
   - **Pricing Plan**: Free（開発用）
6. "Create new project" をクリック（2-3分待つ）

### 1-2. プロジェクトURL・APIキー取得
プロジェクトが作成されたら：
1. 左メニュー "Project Settings" → "API" を開く
2. 以下をメモ：
   - **Project URL**: `https://xxxxx.supabase.co`
   - **anon public key**: `eyJhbGci...`（長い文字列）

### 1-3. Storageバケット作成
1. 左メニュー "Storage" をクリック
2. "Create a new bucket" をクリック
3. 以下を入力：
   - **Name**: `stuff-images`
   - **Public bucket**: チェックを入れる（公開設定）
4. "Create bucket" をクリック

---

## 2. ローカル環境設定（次のステップで自動化）

ここから先は、Supabase CLIとスクリプトで自動化します：
- データベーススキーマの適用
- RLSポリシーの設定
- TypeScript型定義の生成

---

## メモ欄

### プロジェクト情報
```
Project URL: ______________________________
anon public key: ______________________________
Database Password: ______________________________
```

### 完了チェックリスト
- [ ] Supabaseプロジェクト作成完了
- [ ] Project URL・APIキー取得完了
- [ ] Storageバケット `stuff-images` 作成完了

完了したら、次のコマンドを実行してください：
```bash
npm run supabase:setup
```
